package test

import (
	"dagger.io/dagger"

	utilsKubeconfig "github.com/h8r-dev/stacks/chain/v3/internal/utils/kubeconfig"
	"github.com/h8r-dev/stacks/chain/components/infra/crd"
)

dagger.#Plan & {
	client: {
		commands: kubeconfig: {
			name: "cat"
			args: [env.KUBECONFIG]
			stdout: dagger.#Secret
		}
		env: KUBECONFIG: string
	}

	actions: {

		_transformKubeconfig: utilsKubeconfig.#TransformToInternal & {
			input: kubeconfig: client.commands.kubeconfig.stdout
		}

		test: crd.#CreateCloudCRD & {
			input: {
				kubeconfig: _transformKubeconfig.output.kubeconfig
			}
		}
	}
}
