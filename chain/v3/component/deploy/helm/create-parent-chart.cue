package helm

import (
	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"universe.dagger.io/bash"
	"universe.dagger.io/docker"

	"github.com/h8r-dev/stacks/chain/v3/internal/base"
)

#CreateParentChart: {
	input: {
		name: string
		subcharts?: [...dagger.#FS]

		gitOrganization?:       string
		ingressHostPath:        string | *"/"
		rewriteIngressHostPath: bool | *false
		mergeAllCharts:         bool | *false
		repositoryType:         string | *"frontend" | "backend" | "deploy"
	}

	output: {
		chart:   dagger.#FS
		success: bool | *true
	}

	_deps: docker.#Build & {
		steps: [
			base.#Image,
			for fs in input.subcharts {
				docker.#Copy & {
					contents: fs
					dest:     "/helm"
				}
			},
		]
	}

	_sh: core.#Source & {
		path: "."
		include: ["craete-parent-chart.sh"]
	}

	_starter: base.#HelmStarter

	_run: bash.#Run & {
		env: APP_NAME: input.name
		"input": _deps.output
		workdir: "/helm"
		script: {
			directory: _sh.output
			filename:  "craete-parent-chart.sh"
		}
		export: directories: "/helm": _
	}

	output: chart: _run.export.directories."/helm"
}
