package workflow

import (
	"dagger.io/dagger"
	"dagger.io/dagger/core"
)

#Generate: {
	appName:      string
	organization: string
	helmRepo:     string

	output: dagger.#FS & _source.output

	_source: core.#Source & {
		path: "."
		include: ["template"]
	}
}
