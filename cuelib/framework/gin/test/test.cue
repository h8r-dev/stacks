package test

import (
	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"universe.dagger.io/bash"
	"universe.dagger.io/docker"
	"github.com/h8r-dev/stacks/cuelib/internal/utils/base"

	"github.com/h8r-dev/stacks/cuelib/framework/gin"
)

dagger.#Plan & {
	client: {
		env: {
			ORGANIZATION: string
			GITHUB_TOKEN: dagger.#Secret
			KUBECONFIG:   string
		}
	}
	actions: {
		test: {
			testInit
		}
		testInit: {
			_getSourceCode: gin.#Init
			sourceCode:     _getSourceCode.sourceCode

			_deps: docker.#Build & {
				steps: [
					base.#Image,
					docker.#Copy & {
						contents: sourceCode
						dest:     "/workdir/source"
					},
				]
			}

			_sh: core.#Source & {
				path: "."
				include: ["test.sh"]
			}

			bash.#Run & {
				always:  true
				input:   _deps.output
				workdir: "/workdir"
				script: {
					directory: _sh.output
					filename:  "test.sh"
				}
			}
		}
	}
}
