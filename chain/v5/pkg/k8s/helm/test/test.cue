package test

import (
	"dagger.io/dagger"
	"github.com/h8r-dev/stacks/chain/v5/pkg/k8s/helm"
	"github.com/h8r-dev/stacks/chain/v5/pkg/k8s/kubeconfig"
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

		test: repo: helm.#InstallOrUpgrade & {
			input: {
				name:       "ng-test"
				namespace:  "test2"
				repo:       "https://charts.bitnami.com/bitnami"
				chart:      "nginx"
				kubeconfig: _transformKubeconfig.output.kubeconfig
			}
		}
	}
}
