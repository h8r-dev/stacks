package code

import (
	"dagger.io/dagger"
	"dagger.io/dagger/core"
)

#Source: {
	output: dagger.#FS & _sourceCode.output
	_sourceCode: {
		output: _
		...
	}
	{
		framework:   "gin"
		_sourceCode: core.#Source & {
			path: "gin"
		}
	} | {
		framework:   "nextjs"
		_sourceCode: core.#Source & {
			path: "nextjs"
		}
	} | {
		framework:   "spring-boot"
		_sourceCode: core.#Source & {
			path: "maven"
		}
	}
}
