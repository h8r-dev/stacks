package source

import (
	"dagger.io/dagger"
	"dagger.io/dagger/core"
)

#Init: {
	output: dagger.#FS
	{
		framework:   "gin"
		_sourceCode: core.#Source & {
			path: "gin"
		}
		output: _sourceCode.output
	} | {
		framework:   "nextjs"
		_sourceCode: core.#Source & {
			path: "nextjs"
		}
		output: _sourceCode.output
	}
}
