package plans

import (
	"dagger.io/dagger"
	"github.com/h8r-dev/stacks/chain/v3/stack"
)

dagger.#Plan & {
	client: {
		commands: kubeconfig: {
			name: "cat"
			args: [env.KUBECONFIG]
			stdout: dagger.#Secret
		}
		env: {
			ORGANIZATION:    string
			GITHUB_TOKEN:    dagger.#Secret
			KUBECONFIG:      string
			APP_NAME:        string
			APP_DOMAIN:      string | *"h8r.site"
			NETWORK_TYPE:    string | *"default"
			REPO_VISIBILITY: string | *"private"
		}
	}
	actions: up: stack.#Install & {
		args: {
			initRepos:      "false"
			name:           client.env.APP_NAME
			domain:         client.env.APP_DOMAIN
			networkType:    client.env.NETWORK_TYPE
			repoVisibility: client.env.REPO_VISIBILITY
			organization:   client.env.ORGANIZATION
			githubToken:    client.env.GITHUB_TOKEN
			kubeconfig:     client.commands.kubeconfig.stdout
			services: [
				{
					name:       "backend"
					repository: "test1-backend"
				},
				{
					name:       "frontend"
					repository: "test1-frontend"
				},
			]
		}
	}
}
