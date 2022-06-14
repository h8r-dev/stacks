package main

import (
	"dagger.io/dagger"

	// Utility tools
	"github.com/h8r-dev/stacks/chain/internal/utils/base"
	kubeconfigUtil "github.com/h8r-dev/stacks/chain/components/utils/kubeconfig"
	kubectlUtil "github.com/h8r-dev/stacks/chain/components/utils/kubectl"

	// Infra components
	"github.com/h8r-dev/stacks/chain/components/infra/loki"
	"github.com/h8r-dev/stacks/chain/components/infra/nocalhost"
	"github.com/h8r-dev/stacks/chain/components/infra/dapr"
	"github.com/h8r-dev/stacks/chain/components/infra/sealedSecrets"
	"github.com/h8r-dev/stacks/chain/components/infra/prometheus"
	"github.com/h8r-dev/stacks/chain/components/infra/cd/argocd"
)

// TODO: precheck resources that existed in the namespace.
#Plan: {
	kubeconfig:  dagger.#Secret
	networkType: string
	namespace:   string | *"heighliner-infra"

	infra_copmonents: {
		"loki":          loki
		"prometheus":    prometheus
		"nocalhost":     nocalhost
		"dapr":          dapr
		"sealedSecrets": sealedSecrets
		"argocd":        argocd
	}

	// Select the infra components to install.
	// install_list: ["argocd", "loki", "sealedSecrets", "prometheus", "dapr"]
	install_list: ["loki", "sealedSecrets", "prometheus", "dapr"]

	_internalKubeconfig: kubeconfigUtil.#TransformToInternal & {
		input: kubeconfigUtil.#Input & {
			"kubeconfig": kubeconfig
		}
	}

	_kubeconfig: _internalKubeconfig.output.kubeconfig
	_baseImage:  base.#Image & {}

	_createNamespace: kubectlUtil.#CreateNamespace & {
		"namespace": namespace
		kubeconfig:  _kubeconfig
		image:       _baseImage.output
	}

	// Merge into all infra component installation.
	installCD: argocd.#Instance & {
		input: argocd.#Input & {
			waitFor:    _createNamespace.success
			namespace:  _createNamespace.value.contents
			kubeconfig: _kubeconfig
			image:      _baseImage.output
		}
	}

	install: {
		for index, component in install_list {
			"\(component)": infra_copmonents[component].#Instance & {
				input: {
					helmName:      "\(component)"
					image:         _baseImage.output
					"networkType": networkType
					kubeconfig:    _kubeconfig
				}
			}
		}
	}
}

#StoreStateInConfigmap: kubeconfig: dagger.#Secret
