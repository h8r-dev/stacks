package plans

import (
	"dagger.io/dagger"
	"github.com/h8r-dev/stacks/chain/v4/forkenv"
)

dagger.#Plan & {
	client: {
		commands: kubeconfig: {
			name: "cat"
			args: [env.KUBECONFIG]
			stdout: dagger.#Secret
		}
		env: {
			KUBECONFIG:   string | *null
			GITHUB_TOKEN: dagger.#Secret | *null
		}
	}

	actions: up: forkenv.#Fork & {
		args: kubeconfig:  client.commands.kubeconfig.stdout
		args: githubToken: client.env.GITHUB_TOKEN
	}
}
