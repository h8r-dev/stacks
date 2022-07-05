package helm

import (
	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"universe.dagger.io/bash"
	"github.com/h8r-dev/stacks/chain/v3/internal/base"
)

#CreateMicroChart: {
	input: {
		name:     string
		imageURL: string
	}

	output: {
		chart:   dagger.#FS
		success: bool | *true
	}

	_deps: base.#Image

	_sh: core.#Source & {
		path: "."
		include: ["create-micro-chart.sh"]
	}

	_run: bash.#Run & {
		env: {
			NAME:      input.name
			IMAGE_URL: input.imageURL
		}
		"input": _deps.output
		workdir: "/helm"
		script: {
			directory: _sh.output
			filename:  "create-micro-chart.sh"
		}
		export: directories: "/helm": _
	}

	output: chart: _run.export.directories."/helm"
}
