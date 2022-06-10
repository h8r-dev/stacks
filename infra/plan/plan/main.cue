package main

import (
	"dagger.io/dagger"

	// Utility tools
	"github.com/h8r-dev/stacks/chain/components/utils/kubeconfig"
)

dagger.#Plan & {
	client: {
		commands: kubeconfig: {
			name: "cat"
			args: ["\(env.KUBECONFIG)"]
			stdout: dagger.#Secret
		}

		env: {
			KUBECONFIG:   string
			NETWORK_TYPE: string | *"default"
		}
	}

	actions: {
		_kubeconfig: kubeconfig.#TransformToInternal & {
			input: kubeconfig.#Input & {
				kubeconfig: client.commands.kubeconfig.stdout
			}
		}

		up: {
			executePlan: plan: #Plan & {
				kubeconfig:  client.commands.kubeconfig.stdout
				networkType: client.env.NETWORK_TYPE
			}

			// Store install status in a Configmap resource in K8S.
			// storeState: {

			// }
		}
	}
}
