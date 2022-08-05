package test

import (
	"dagger.io/dagger"
	"universe.dagger.io/bash"
	"github.com/h8r-dev/stacks/chain/v5/service/dockerfile"
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
			_gin:    gin
			_maven:  maven
			_static: frontendStatic
			_cmd:    frontendCmd
		}
		gin: {
			_source: dockerfile.#Generate & {
				isGenerated: false
				type:        "backend"
				language: {
					name:    "golang"
					version: "1.19"
				}
				framework: "gin"
			}
			_check: #CatFile & {
				fs:   _source.output
				path: "Dockerfile"
			}
		}
		maven: {
			_source: dockerfile.#Generate & {
				isGenerated: true
				type:        "backend"
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
		frontendCmd: {
			_source: dockerfile.#Generate & {
				isGenerated: true
				type:        "frontend-cmd"
				language: {
					name:    "typescript"
					version: "4.7"
				}
				framework: "nextjs"
				setting: extension: {
					frontendBuildCMD: "yarn install --frozen-locakfile && yarn build"
					frontendOutDir:   "/"
					frontendRunCMD:   "yarn start"
				}
			}
			_check: #CatFile & {
				fs:   _source.output
				path: "Dockerfile"
			}
		}
		frontendStatic: {
			_source: dockerfile.#Generate & {
				isGenerated: true
				type:        "frontend-static"
				language: {
					name:    "typescript"
					version: "4.7"
				}
				framework: "previousjs"
				setting: extension: {
					frontendBuildCMD: "npm install && npm run build"
					frontendOutDir:   "dist/"
					frontendAppType:  "MPA"
					frontend404Path:  "/404.html"
				}
			}
			_check: #CatFile & {
				fs:   _source.output
				path: "nginx.conf"
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
