package test

import (
	"dagger.io/dagger"
	"github.com/h8r-dev/stacks/chain/v4/cd/argocd"
	"github.com/h8r-dev/stacks/chain/v4/pkg/k8s/kubeconfig"

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
		_transformKubeconfig: kubeconfig.#TransformToInternal & {
			input: kubeconfig: client.commands.kubeconfig.stdout
		}
		_kubeconfig: _transformKubeconfig.output.kubeconfig

		test: argocd.#ApplicationSet & {
			name:       "forkmain"
			repo:       "https://github.com/deer-org/forkmain-deploy"
			kubeconfig: _kubeconfig
		}
	}
}
