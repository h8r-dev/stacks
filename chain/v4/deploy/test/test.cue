package test

import (
	"dagger.io/dagger"
	"github.com/h8r-dev/stacks/chain/v4/deploy"
	"github.com/h8r-dev/stacks/chain/v4/pkg/k8s/kubeconfig"
	"github.com/h8r-dev/stacks/chain/v4/internal/addon"

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

		_infra: addon.#ReadInfraConfig & {
			input: kubeconfig: _kubeconfig
		}

		test: deploy.#Init & {
			args:       _
			kubeconfig: _kubeconfig
			cdVar:      _infra.argoCD
		}
	}
}
