package next

import (
	"dagger.io/dagger"
	"dagger.io/dagger/core"
)

#Init: {
	output: sourceCode: dagger.#FS

	output: sourceCode: _sourceCode.output

	_sourceCode: core.#Source & {
		path: "template"
	}
}
