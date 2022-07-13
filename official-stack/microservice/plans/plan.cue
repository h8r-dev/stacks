package plans

import (
	"dagger.io/dagger"
	"github.com/h8r-dev/stacks/chain/v4/stack"
)

dagger.#Plan & {
	client: {
		commands: kubeconfig: {
			name: "cat"
			args: [env.KUBECONFIG]
			stdout: dagger.#Secret
		}
		env: {
			KUBECONFIG:   string
			GITHUB_TOKEN: dagger.#Secret
		}
	}
	actions: up: stack.#Install & {
		args: {
			kubeconfig:    client.commands.kubeconfig.stdout
			githubToken:   client.env.GITHUB_TOKEN
			imagePassword: client.env.GITHUB_TOKEN
		}
	}
}
