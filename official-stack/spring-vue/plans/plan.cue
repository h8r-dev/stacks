package main

import (
	"dagger.io/dagger"
	"github.com/h8r-dev/stacks/chain/factory/scaffoldfactory"
	"github.com/h8r-dev/stacks/chain/factory/scmfactory"
	"github.com/h8r-dev/stacks/chain/factory/cdfactory"
	"github.com/h8r-dev/stacks/chain/components/utils/statewriter"
	"github.com/h8r-dev/stacks/chain/components/utils/kubeconfig"
	"github.com/h8r-dev/stacks/chain/factory/basefactory"
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
			APP_DOMAIN:   string | *"h8r.site"
		}

		filesystem: "output.yaml": write: contents: actions.up._output.contents
	}

	actions: {
		_domain: basefactory.#DefaultDomain & {
			application: domain: client.env.APP_DOMAIN
			infra: domain:       client.env.APP_DOMAIN
		}

		_kubeconfig: kubeconfig.#TransformToInternal & {
			input: kubeconfig.#Input & {
				kubeconfig: client.commands.kubeconfig.stdout
			}
		}

		_scaffold: scaffoldfactory.#Instance & {
			input: scaffoldfactory.#Input & {
				domain:              _domain
				organization:        client.env.ORGANIZATION
				personalAccessToken: client.env.GITHUB_TOKEN
				repository: [
					{
						name:      client.env.APP_NAME + "-frontend"
						type:      "frontend"
						framework: "vue"
						ci:        "github"
						registry:  "github"
					},
					{
						name:      client.env.APP_NAME + "-backend"
						type:      "backend"
						framework: "spring"
						ci:        "github"
						registry:  "github"
						deployTemplate: helmStarter: "helm-starter/java/spring-boot"
						extraArgs: helmSet: """
						'.service.labels = {"h8r.io/framework": "spring"}'
						"""
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
					domain:      _domain
				}
			}

			_output: statewriter.#Output & {
				input: _cd.output
			}
		}
	}
}
