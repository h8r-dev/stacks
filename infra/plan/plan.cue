package main

import (
	"dagger.io/dagger"
	"universe.dagger.io/docker"

	// Utility tools
	"github.com/h8r-dev/stacks/chain/internal/utils/base"

	// Infra components
	"github.com/h8r-dev/stacks/chain/components/addons/loki"
	"github.com/h8r-dev/stacks/chain/components/addons/nocalhost"
	"github.com/h8r-dev/stacks/chain/components/addons/dapr"
	"github.com/h8r-dev/stacks/chain/components/addons/sealedSecrets"
	"github.com/h8r-dev/stacks/chain/components/addons/prometheus"
	"github.com/h8r-dev/stacks/chain/components/cd/argocd"
)

#Plan: {
	kubeconfig:  dagger.#Secret
	networkType: string

	infra_copmonents: {
		"loki":          loki
		"prometheus":    prometheus
		"nocalhost":     nocalhost
		"dapr":          dapr
		"sealedSecrets": sealedSecrets
		"argocd":        argocd
	}

	install_list: ["argocd", "loki", "prometheus", "nocalhost", "dapr", "sealedSecrets"]

	_baseImage: base.#Image & {}

	installCD: argocd: argocd

	installInfra: {
		for component, index in install_list {
			"\(component)": infra_copmonents[component].#Instance & {
				_output: docker.#Image
				if index == 0 {
					_output: _baseImage.output
				}
				if index > 0 {
					_output: installComponents["\(index-1)"].output.image
				}
				input: {
					helmName:    "h8r-infra-compnents"
					image:       _output
					networkType: input.networkType
				}
			}
		}
	}
}

#StoreStateInConfigmap: kubeconfig: dagger.#Secret
