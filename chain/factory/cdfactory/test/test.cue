package test

import (
	"dagger.io/dagger"
	"github.com/h8r-dev/stacks/chain/factory/scaffoldfactory"
	"github.com/h8r-dev/stacks/chain/factory/scmfactory"
	"github.com/h8r-dev/stacks/chain/factory/cdfactory"
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
			APP_NAME:     string
		}
	}
	actions: {
		_input: scaffoldfactory.#Input & {
			scm:                 "github"
			organization:        client.env.ORGANIZATION
			personalAccessToken: client.env.GITHUB_TOKEN
			repository: [
				{
					name:      client.env.APP_NAME + "-frontend"
					type:      "frontend"
					framework: "next"
					ci:        "github"
					registry:  "github"
					extraArgs: helmSet: """
						'.securityContext = {"runAsUser": 0}'
						"""
				},
				{
					name:      client.env.APP_NAME + "-backend"
					type:      "backend"
					framework: "gin"
					ci:        "github"
					registry:  "github"
				},
				{
					name:      client.env.APP_NAME + "-deploy"
					type:      "deploy"
					framework: "helm"
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

		_gitInput: scmfactory.#Input & {
			provider:            "github"
			personalAccessToken: client.env.GITHUB_TOKEN
			organization:        client.env.ORGANIZATION
			repositorys:         _run.output.image
			visibility:          "private"
			kubeconfig:          client.commands.kubeconfig.stdout
		}

		_git: scmfactory.#Instance & {
			input: _gitInput
		}

		_cdInput: cdfactory.#Input & {
			provider:    "argocd"
			repositorys: _git.output.image
			kubeconfig:  client.commands.kubeconfig.stdout
		}

		test: cdfactory.#Instance & {
			input: _cdInput
		}
	}
}
