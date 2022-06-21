package test

import (
	"dagger.io/dagger"
	"github.com/h8r-dev/stacks/chain/v3/component/cd/argocd"
	"github.com/h8r-dev/stacks/chain/v3/internal/addon"
	utilsKubeconfig "github.com/h8r-dev/stacks/chain/v3/internal/utils/kubeconfig"
)

dagger.#Plan & {
	client: {
		commands: kubeconfig: {
			name: "cat"
			args: [env.KUBECONFIG]
			stdout: dagger.#Secret
		}
		env: {
			ORGANIZATION: string
			GITHUB_TOKEN: dagger.#Secret
			APP_NAME:     string
			REPO_URL:     string
			KUBECONFIG:   string
		}
	}

	actions: {
		_transformKubeconfig: utilsKubeconfig.#TransformToInternal & {
			input: kubeconfig: client.commands.kubeconfig.stdout
		}

		_infra: addon.#ReadInfraConfig & {
			input: kubeconfig: _transformKubeconfig.output.kubeconfig
		}

		test: argocd.#CreateApp & {
			input: {
				name:               client.env.APP_NAME
				repositoryPassword: client.env.GITHUB_TOKEN
				repositoryURL:      client.env.REPO_URL
				appPath:            "\(name)"
				argoVar:            _infra.argoCD
			}
		}
	}
}
