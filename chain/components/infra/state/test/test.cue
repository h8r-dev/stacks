package test

import (
	"dagger.io/dagger"
	"github.com/h8r-dev/stacks/chain/components/infra/state"
	utilsKubeconfig "github.com/h8r-dev/stacks/chain/v3/internal/utils/kubeconfig"
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

		test: state.#SetConfigMap & {
			kubeconfig: _transformKubeconfig.output.kubeconfig
		}
	}
}
