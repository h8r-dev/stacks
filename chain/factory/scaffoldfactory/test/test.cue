package test

import (
	"dagger.io/dagger"
	"universe.dagger.io/bash"
	"github.com/h8r-dev/stacks/chain/factory/scaffoldfactory"
)

dagger.#Plan & {
	client: {
		commands: kubeconfig: {
			name: "cat"
			args: ["\(env.KUBECONFIG)"]
			stdout: dagger.#Secret
		}
		env: {
			ORGANIZATION:   string
			GITHUB_TOKEN:   dagger.#Secret
			KUBECONFIG:     string
			CLOUD_PROVIDER: string
		}
	}
	actions: {
		_input: scaffoldfactory.#Input & {
			scm:                 "github"
			organization:        "lyzhang1999"
			personalAccessToken: client.env.GITHUB_TOKEN
			cloudProvider:       client.env.CLOUD_PROVIDER
			repository: [
				{
					name:       "cart1-frontend"
					type:       "frontend"
					framework:  "next"
					visibility: "private"
					ci:         "github"
					registry:   "github"
				},
				{
					name:       "cart1-backend"
					type:       "backend"
					framework:  "gin"
					visibility: "private"
					ci:         "github"
					registry:   "github"
				},
				{
					name:       "cart1-deploy"
					type:       "deploy"
					framework:  "helm"
					visibility: "private"
				},
			]
			addons: [
				// {
				//  name: "ingress-nginx"
				// },
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
		_run: scaffoldfactory.#Instance & {
			input: _input
		}
		test: bash.#Run & {
			input:  _run.output.image
			always: true
			script: contents: """
				ls /scaffold
				ls /scaffold/cart1-deploy/infra
				ls /scaffold/cart1-deploy/infra/ingress-nginx
				"""
		}
	}
}
