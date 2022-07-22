package test

import (
	"dagger.io/dagger"
	"universe.dagger.io/bash"
	"github.com/h8r-dev/stacks/chain/v4/service/dockerfile"
	"github.com/h8r-dev/stacks/chain/v4/pkg/k8s/kubeconfig"
	"github.com/h8r-dev/stacks/chain/v4/internal/base"
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
	actions: {
		_transformKubeconfig: kubeconfig.#TransformToInternal & {
			input: kubeconfig: client.commands.kubeconfig.stdout
		}
		_kubeconfig: _transformKubeconfig.output.kubeconfig
		_deps:       base.#Image
		test: {
			_gin:    gin
			_nextjs: nextjs
		}
		gin: {
			_source: dockerfile.#Generate & {
				isGenerated: false
				language: {
					name:    "golang"
					version: "1.17"
				}
				framework: "gin"
				// setting: extension: entryFile: "/cmd/main.go"
			}
			_check: bash.#Run & {
				input:   _deps.output
				always:  true
				workdir: "/workdir"
				mounts: dockerfile: {
					dest:     "/workdir"
					type:     "fs"
					contents: _source.output
				}
				script: contents: "cat Dockerfile"
			}
		}
		nextjs: {
			_source: dockerfile.#Generate & {
				isGenerated: true
				language: {
					name:    "typescript"
					version: "4.7"
				}
				framework: "nextjs"
			}
			_check: bash.#Run & {
				input:   _deps.output
				always:  true
				workdir: "/workdir"
				mounts: dockerfile: {
					dest:     "/workdir"
					type:     "fs"
					contents: _source.output
				}
				script: contents: "cat Dockerfile"
			}
		}
	}
}
