package main

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
			ORGANIZATION:   string
			GITHUB_TOKEN:   dagger.#Secret
			KUBECONFIG:     string
			CLOUD_PROVIDER: string
			APP_NAME:       string
		}
	}
	actions: {
		_scaffold: scaffold.#Instance & {
			input: scaffold.#Input & {
				scm:                 "github"
				organization:        client.env.ORGANIZATION
				personalAccessToken: client.env.GITHUB_TOKEN
				cloudProvider:       client.env.CLOUD_PROVIDER
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
					{
						name: "ingress-nginx"
					},
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
		}

		_git: scm.#Instance & {
			input: scm.#Input & {
				provider:            "github"
				personalAccessToken: client.env.GITHUB_TOKEN
				organization:        client.env.ORGANIZATION
				repositorys:         _scaffold.output.image
				visibility:          "private"
			}
		}

		up: cd.#Instance & {
			input: cd.#Input & {
				provider:    "argocd"
				repositorys: _git.output.image
				kubeconfig:  client.commands.kubeconfig.stdout
			}
		}
	}
}
