package test

import (
	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"github.com/h8r-dev/stacks/chain/v3/component/framework/gin"
	"github.com/h8r-dev/stacks/chain/v3/component/framework/next"
	"github.com/h8r-dev/stacks/chain/v3/internal/base"
	"universe.dagger.io/bash"
	"universe.dagger.io/docker"
)

dagger.#Plan & {
	client: env: {
		ORGANIZATION: string
		GITHUB_TOKEN: dagger.#Secret
		KUBECONFIG:   string
	}
	actions: {
		test: {
			gin:  testGin
			next: testNext
		}
		_ginCode: gin.#Init
		testGin:  #listSourceCode & {
			sourceCode: _ginCode.output.sourceCode
		}
		_nextCode: next.#Init
		testNext:  #listSourceCode & {
			sourceCode: _nextCode.output.sourceCode
		}
	}
}

#listSourceCode: {
	sourceCode: dagger.#FS

	_deps: docker.#Build & {
		steps: [
			base.#Image,
			docker.#Copy & {
				contents: sourceCode
				dest:     "/workdir"
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
