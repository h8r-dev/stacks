package middleware

import (
	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"universe.dagger.io/bash"
	"github.com/h8r-dev/stacks/chain/v5/internal/base"
)

#Init: {
	args: _
	_chart: {
		for m in args.middleware {
			(m.name): #Config & {
				mid:  m
				type: m.type
			}
		}
	}
	output: charts: [...dagger.#FS]
	output: charts: [ for m in args.middleware {_chart[(m.name)].output}]
}

#Config: {
	mid:    _
	output: dagger.#FS
	{
		_chart: #chart & {
			input: {
				set:     """
					.auth.username = "\(mid.username)" |
					.auth.password = "\(mid.password)" |
					.auth.database = "\(mid.database[0].name)" |
					.primary.persistence.size = "\(mid.setting.storage)" |
					.fullnameOverride = "postgresql"
					"""
				version: "11.6.17"
				repo:    "https://charts.bitnami.com/bitnami"
				chart:   "postgresql"
			}
		}
		output: _chart.output.chart
		type:   "postgres"
	} | {
		type: "redis"
	}
}

#chart: {
	input: {
		version: string | *""
		set:     string | *""
		repo:    string
		chart:   string
		waitFor: bool | *true
	}

	_deps: base.#Image

	_sh: core.#Source & {
		path: "."
		include: ["chart.sh"]
	}

	_run: bash.#Run & {
		env: {
			VERSION:  input.version
			SET:      input.set
			REPO:     input.repo
			CHART:    input.chart
			WAIT_FOR: "\(input.waitFor)"
		}
		"input": _deps.output
		workdir: "/helm"
		script: {
			directory: _sh.output
			filename:  "chart.sh"
		}
		export: directories: "/helm": _
	}
	output: {
		success: _run.success
		chart:   _run.export.directories."/helm"
	}
}
