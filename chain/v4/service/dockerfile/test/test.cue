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
		test: {
			_gin:    gin
			_nextjs: nextjs
			_maven:  maven
		}
		gin: {
			_source: dockerfile.#Generate & {
				isGenerated: false
				language: {
					name:    "golang"
					version: "1.17"
				}
				framework: "gin"
			}
			_check: #CatFile & {
				fs:   _source.output
				path: "Dockerfile"
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
			_check: #CatFile & {
				fs:   _source.output
				path: "Dockerfile"
			}
		}
		maven: {
			_source: dockerfile.#Generate & {
				isGenerated: true
				language: {
					name:    "java"
					version: "11"
				}
				framework: "spring-boot"
				setting: extension: buildTool: "maven"
			}
			_check: #CatFile & {
				fs:   _source.output
				path: "Dockerfile"
			}
		}
	}
}

#CatFile: {
	fs:    dagger.#FS
	path:  string
	_deps: base.#Image
	_run:  bash.#Run & {
		input:   _deps.output
		always:  true
		workdir: "/workdir"
		mounts: dockerfile: {
			dest:     "/workdir"
			type:     "fs"
			contents: fs
		}
		script: contents: "cat \(path)"
	}
}
