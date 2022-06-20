package main

import (
	"dagger.io/dagger"
	"universe.dagger.io/bash"

	// Utility tools
	"github.com/h8r-dev/stacks/chain/internal/utils/base"
	kubeconfigUtil "github.com/h8r-dev/stacks/chain/v3/internal/utils/kubeconfig"
	kubectlUtil "github.com/h8r-dev/stacks/chain/components/utils/kubectl"

	// Infra components
	"github.com/h8r-dev/stacks/chain/components/infra/loki"
	"github.com/h8r-dev/stacks/chain/components/infra/nocalhost"
	"github.com/h8r-dev/stacks/chain/components/infra/dapr"
	"github.com/h8r-dev/stacks/chain/components/infra/sealedSecrets"
	"github.com/h8r-dev/stacks/chain/components/infra/prometheus"
	"github.com/h8r-dev/stacks/chain/components/infra/cd/argocd"
	"github.com/h8r-dev/stacks/chain/components/infra/heighliner/dashboard"

	// State management
	"github.com/h8r-dev/stacks/chain/components/infra/state"
	"github.com/h8r-dev/stacks/chain/components/infra/crd"
)

// TODO: precheck resources that existed in the namespace.
#Plan: {
	kubeconfig:       dagger.#Secret
	withoutDashboard: string | *"false"
	networkType:      string
	namespace:        string | *"heighliner-infra"
	domain:           string

	infra_copmonents: {
		"loki":          loki
		"prometheus":    prometheus
		"nocalhost":     nocalhost
		"dapr":          dapr
		"sealedSecrets": sealedSecrets
		"argocd":        argocd
		"dashboard":     dashboard
	}

	// Select the infra components to install.
	// install_list: ["argocd", "loki", "sealedSecrets", "prometheus", "dapr"]
	install_list: ["loki", "sealedSecrets", "prometheus", "dashboard"]

	_internalKubeconfig: kubeconfigUtil.#TransformToInternal & {
		input: "kubeconfig": kubeconfig
	}

	_kubeconfig:         _internalKubeconfig.output.kubeconfig
	_originalKubeconfig: _internalKubeconfig.output.originalKubeconfig
	_baseImage:          base.#Image & {}

	_createNamespace: kubectlUtil.#CreateNamespace & {
		"namespace": namespace
		kubeconfig:  _kubeconfig
		image:       _baseImage.output
	}

	// Merge into all infra component installation.
	_installCD: argocd.#Instance & {
		input: argocd.#Input & {
			waitFor:       _createNamespace.success
			namespace:     "argocd"
			kubeconfig:    _kubeconfig
			image:         _baseImage.output
			"networkType": networkType
		}
	}

	_install: {
		for index, component in install_list {
			"\(component)": infra_copmonents[component].#Instance & {
				input: {
					waitFor:       _createNamespace.success
					namespace:     _createNamespace.value.contents
					helmName:      "\(component)"
					image:         _baseImage.output
					"networkType": networkType
					kubeconfig:    _kubeconfig
					if "\(component)" == "dashboard" {
						originalKubeconfig: _originalKubeconfig
						"withoutDashboard": withoutDashboard
					}
				}
			}
		}
	}

	_waitInstall: {
		bash.#Run & {
			input: _baseImage.output
			env: {
				for component in install_list {
					"\(component)": "\(_install[(component)].output.success)"
				}
				argocd: "\(_installCD.output.success)"
			}
			script: contents: "echo 'wait for install'"
		}
	}

	_setInfraConfig: {
		state.#SetConfigMap & {
			waitFor:    "\(_waitInstall.success)"
			kubeconfig: _kubeconfig
		}
	}

	_createCloudCRD: crd.#CreateCloudCRD & {
		input: {
			kubeconfig: _kubeconfig
		}
	}
}
