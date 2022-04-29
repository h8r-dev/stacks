package main

import (
	"dagger.io/dagger"
	"github.com/h8r-dev/chain/supply/scaffold"
	"github.com/h8r-dev/chain/supply/output"
	"github.com/h8r-dev/chain/supply/scm"
	"github.com/h8r-dev/chain/supply/cd"
	"github.com/h8r-dev/chain/tools/kubeconfig"
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
			KUBECONFIG:   string | *""
			APP_NAME:     string
		}
		filesystem: "output.yaml": write: contents: actions.up._output.contents
	}
	actions: {
		_kubeconfig: kubeconfig.#TransformToInternal & {
			input: kubeconfig.#Input & {
				kubeconfig: client.commands.kubeconfig.stdout
			}
		}
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
				kubeconfig:          _kubeconfig.output.kubeconfig
			}
		}

		up: {
			_cd: cd.#Instance & {
				input: cd.#Input & {
					provider:    "argocd"
					repositorys: _git.output.image
					kubeconfig:  _kubeconfig.output.kubeconfig
				}
			}
			_output: output.#Output & {
				input: _cd.output
			}
		}
	}
}
