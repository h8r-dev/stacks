package main

import (
	"dagger.io/dagger"

	// Utility tools
	"github.com/h8r-dev/stacks/chain/internal/utils/base"

	// Infra components
	"github.com/h8r-dev/stacks/chain/components/infra/loki"
	"github.com/h8r-dev/stacks/chain/components/infra/nocalhost"
	"github.com/h8r-dev/stacks/chain/components/infra/dapr"
	"github.com/h8r-dev/stacks/chain/components/infra/sealedSecrets"
	"github.com/h8r-dev/stacks/chain/components/infra/prometheus"
	"github.com/h8r-dev/stacks/chain/components/infra/cd/argocd"
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

	// Select the infra components to install.
	// install_list: ["argocd", "loki", "prometheus", "nocalhost", "dapr", "sealedSecrets"]
	// install_list: ["loki", "prometheus", "nocalhost", "dapr", "sealedSecrets"]
	install_list: ["loki", "sealedSecrets", "prometheus"]
	// install_list: ["loki", "sealedSecrets"]

	_baseImage: base.#Image & {}

	// Merge into all infra component installation.
	// installCD: argocd.#Instance & {
	//  input: argocd.#Input & {
	//   "kubeconfig": kubeconfig
	//   image:        _baseImage.output
	//  }
	// }

	install: {
		for index, component in install_list {
			"\(component)": infra_copmonents[component].#Instance & {
				input: {
					helmName:      "\(component)"
					image:         _baseImage.output
					"networkType": networkType
					"kubeconfig":  kubeconfig
				}
			}
		}
	}
}

#StoreStateInConfigmap: kubeconfig: dagger.#Secret
