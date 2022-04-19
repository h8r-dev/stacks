package test

import (
	"dagger.io/dagger"
	"github.com/h8r-dev/chain/supply/scaffold"
	"github.com/h8r-dev/chain/supply/scm"
	"github.com/h8r-dev/chain/supply/cd"
)

dagger.#Plan & {
	client: {
		commands: kubeconfig: {
			name: "cat"
			args: ["\(env.KUBECONFIG)"]
			stdout: dagger.#Secret
		}
		env: {
			ORGANIZATION: string
			GITHUB_TOKEN: dagger.#Secret
			KUBECONFIG:   string
		}
	}
	actions: {
		_input: scaffold.#Input & {
			scm:          "github"
			organization: "lyzhang1999"
			repository: [
				{
					name:       "cart1-frontend"
					type:       "frontend"
					framework:  "next"
					visibility: "private"
					ci:         "github"
				},
				{
					name:       "cart1-backend"
					type:       "backend"
					framework:  "gin"
					visibility: "private"
					ci:         "github"
				},
				{
					name:       "cart1-deploy"
					type:       "deploy"
					framework:  "helm"
					visibility: "private"
				},
			]
			addons: [
				{
					name: "prometheus"
				},
				{
					name: "loki"
				},
				{
					name: "nocalhost"
				},
			]
		}
		_run: scaffold.#Instance & {
			input: _input
		}

		_gitInput: scm.#Input & {
			provider:            "github"
			personalAccessToken: client.env.GITHUB_TOKEN
			organization:        client.env.ORGANIZATION
			repositorys:         _run.output.image
		}

		_git: scm.#Instance & {
			input: _gitInput
		}

		_cdInput: cd.#Input & {
			provider:    "argocd"
			repositorys: _git.output.image
			kubeconfig:  client.commands.kubeconfig.stdout
		}

		test: cd.#Instance & {
			input: _cdInput
		}
	}
}
