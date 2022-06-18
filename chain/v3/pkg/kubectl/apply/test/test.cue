package test

import (
	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"universe.dagger.io/bash"
	"github.com/h8r-dev/stacks/chain/v3/internal/base"
	"github.com/h8r-dev/stacks/chain/v3/pkg/kubectl/apply"
	utilsKubeconfig "github.com/h8r-dev/stacks/chain/v3/internal/utils/kubeconfig"
)

dagger.#Plan & {
	client: {
		commands: kubeconfig: {
			name: "cat"
			args: [env.KUBECONFIG]
			stdout: dagger.#Secret
		}
		env: KUBECONFIG: string
	}
	actions: test: {
		_transformKubeconfig: utilsKubeconfig.#TransformToInternal & {
			input: kubeconfig: client.commands.kubeconfig.stdout
		}

		_kubeconfig: _transformKubeconfig.output.kubeconfig

		_deps: base.#Image

		_sh: core.#Source & {
			path: "."
			include: ["test.sh"]
		}

		_manifests: core.#Source & {
			path: "."
			include: ["manifest.yaml"]
		}

		_applyDir: apply.#Dir & {
			input: {
				kubeconfig: _kubeconfig
				manifests:  _manifests.output
			}
		}

		_applyFile: apply.#File & {
			input: {
				kubeconfig: _kubeconfig
				contents: #"""
					apiVersion: v1
					kind: ConfigMap
					metadata:
					  name: stack-test-configmap
					data:
					  # property-like keys; each key maps to a simple value
					  player_initial_lives: "3"
					  ui_properties_file_name: "user-interface.properties"

					  # file-like keys
					  game.properties: |
					    enemy.types=aliens,monsters
					    player.maximum-lives=5    
					  user-interface.properties: |
					    color.good=purple
					    color.bad=yellow
					    allow.textmode=true
					"""#
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
