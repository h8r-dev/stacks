package main

import (
	"dagger.io/dagger"
	"github.com/h8r-dev/chain/supply/scaffold"
	"github.com/h8r-dev/chain/supply/scm"
	"github.com/h8r-dev/chain/supply/cd"
)

dagger.#Plan & {
	client: {
		commands: {
			if env.KUBECONFIG != "" {
				kubeconfig: {
					name: "sh"
					args: ["-c", "cat \(env.KUBECONFIG) | sed -e 's?server: https://.*?server: https://kubernetes.default.svc?'"]
					stdout: dagger.#Secret
				}
			}
			if env.KUBECONFIG == "" {
				kubeconfig: {
					name: "sh"
					args: ["-c", "kubectl config view --flatten --minify | sed -e 's?server: https://.*?server: https://kubernetes.default.svc?'"]
					stdout: dagger.#Secret
				}
			}
		}

		env: {
			ORGANIZATION: string
			GITHUB_TOKEN: dagger.#Secret
			KUBECONFIG:   string | *""
			APP_NAME:     string
		}
	}

	actions: {
		_scaffold: scaffold.#Instance & {
			input: scaffold.#Input & {
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
					},
					{
						name:      client.env.APP_NAME + "-deploy"
						type:      "deploy"
						framework: "helm"
					},
				]
				addons: []
			}
		}

		_git: scm.#Instance & {
			input: scm.#Input & {
				provider:            "github"
				personalAccessToken: client.env.GITHUB_TOKEN
				organization:        client.env.ORGANIZATION
				repositorys:         _scaffold.output.image
				visibility:          "private"
				kubeconfig:          client.commands.kubeconfig.stdout
			}
		}

		up: _cd: cd.#Instance & {
			input: cd.#Input & {
				provider:    "argocd"
				repositorys: _git.output.image
				kubeconfig:  client.commands.kubeconfig.stdout
			}
		}
	}
}
