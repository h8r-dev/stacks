package test

import (
	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"universe.dagger.io/bash"
	"github.com/h8r-dev/stacks/chain/v3/internal/base"
	"github.com/h8r-dev/stacks/chain/v3/internal/state"
	utilsKubeconfig "github.com/h8r-dev/stacks/chain/v3/internal/utils/kubeconfig"
	"github.com/h8r-dev/stacks/chain/v3/internal/var"
)

dagger.#Plan & {
	client: {
		commands: kubeconfig: {
			name: "cat"
			args: [env.KUBECONFIG]
			stdout: dagger.#Secret
		}
		env: {
			KUBECONFIG:   string
			APP_NAME:     string
			ORGANIZATION: string
		}
	}
	actions: test: {

		_var: var.#Generator & {
			input: {
				applicationName: client.env.APP_NAME
				domain:          "h8r.site"
				networkType:     "default"
				organization:    client.env.ORGANIZATION
				frameworks: [
					{
						name: "gin"
					},
					{
						name: "next"
					},
				]
				addons: [
					{
						name: "nocalhost"
					},
					{
						name: "prometheus"
					},
				]
			}
		}

		_transformKubeconfig: utilsKubeconfig.#TransformToInternal & {
			input: kubeconfig: client.commands.kubeconfig.stdout
		}

		_kubeconfig: _transformKubeconfig.output.kubeconfig

		_deps: base.#Image

		_sh: core.#Source & {
			path: "."
			include: ["test.sh"]
		}

		_writeStates: state.#Write & {
			input: {
				kubeconfig: _kubeconfig
				frameworks: _var.input.frameworks
				vars:       _var
			}
		}

		bash.#Run & {
			always:  true
			input:   _deps.output
			workdir: "/workdir"
			mounts: kubeconfig: {
				dest:     "/root/.kube/config"
				contents: _kubeconfig
			}
			script: {
				directory: _sh.output
				filename:  "test.sh"
			}
		}
	}
}
