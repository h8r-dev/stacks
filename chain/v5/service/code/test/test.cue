package test

import (
	"dagger.io/dagger"
	"universe.dagger.io/bash"
	"github.com/h8r-dev/stacks/chain/v5/service/code"
	"github.com/h8r-dev/stacks/chain/v5/pkg/k8s/kubeconfig"
	"github.com/h8r-dev/stacks/chain/v5/internal/base"
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
			_gin:      gin
			_maven:    maven
			_nextjs:   nextjs
			_reactCli: reactCli
			_vueCli:   vueCli
			_vueVite:  vueVite
			_js:       js
		}
		gin: {
			_source: code.#Source & {
				framework: "gin"
			}
			_check: #LsFile & {
				fs:   _source.output
				path: "."
			}
		}
		maven: {
			_source: code.#Source & {
				framework: "spring-boot"
			}
			_check: #LsFile & {
				fs:   _source.output
				path: "."
			}
		}
		nextjs: {
			_source: code.#Source & {
				framework: "nextjs"
			}
			_check: #LsFile & {
				fs:   _source.output
				path: "."
			}
		}
		reactCli: {
			_source: code.#Source & {
				framework: "react-cli"
			}
			_check: #LsFile & {
				fs:   _source.output
				path: "."
			}
		}
		vueCli: {
			_source: code.#Source & {
				framework: "vue-cli"
			}
			_check: #LsFile & {
				fs:   _source.output
				path: "."
			}
		}
		vueVite: {
			_source: code.#Source & {
				framework: "vue-vite"
			}
			_check: #LsFile & {
				fs:   _source.output
				path: "."
			}
		}
		js: {
			_source: code.#Source & {
				framework: "js"
			}
			_check: #LsFile & {
				fs:   _source.output
				path: "."
			}
		}
	}
}

#LsFile: {
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
		script: contents: "ls -lah \(path)"
	}
}
