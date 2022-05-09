package main

import (
	"dagger.io/dagger"
	"github.com/h8r-dev/stacks/chain/factory/scaffoldfactory"
	"github.com/h8r-dev/stacks/chain/factory/scmfactory"
	"github.com/h8r-dev/stacks/chain/factory/cdfactory"
	"github.com/h8r-dev/stacks/chain/components/utils/statewriter"
	"github.com/h8r-dev/stacks/chain/components/utils/kubeconfig"
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
		filesystem: "output.yaml": write: contents: actions.up._output.contents
	}
	actions: {
		_kubeconfig: kubeconfig.#TransformToInternal & {
			input: kubeconfig.#Input & {
				kubeconfig: client.commands.kubeconfig.stdout
			}
		}
		_scaffold: scaffoldfactory.#Instance & {
			input: scaffoldfactory.#Input & {
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

		_git: scmfactory.#Instance & {
			input: scmfactory.#Input & {
				provider:            "github"
				personalAccessToken: client.env.GITHUB_TOKEN
				organization:        client.env.ORGANIZATION
				repositorys:         _scaffold.output.image
				visibility:          "private"
				kubeconfig:          _kubeconfig.output.kubeconfig
			}
		}

		up: {
			_cd: cdfactory.#Instance & {
				input: cdfactory.#Input & {
					provider:    "argocd"
					repositorys: _git.output.image
					kubeconfig:  _kubeconfig.output.kubeconfig
				}
			}
			_output: statewriter.#Output & {
				input: _cd.output
			}
		}
	}
}
