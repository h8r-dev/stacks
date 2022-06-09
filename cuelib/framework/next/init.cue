package next

import (
	"dagger.io/dagger/core"
	"universe.dagger.io/bash"
	"universe.dagger.io/docker"
)

#Init: {
	sourceCode: "printf(hello world)"
	_deps:      docker.#Pull & {
		source: "lyzhang1999/ubuntu:latest@sha256:d265807ca17db2610100b102ccbfa285ae73c78e5666078508d20d1415e3c01c"
	}
	_sh: core.#Source & {
		path: "."
		include: ["init.sh"]
	}
	bash.#Run & {
		always:  true
		input:   _deps.output
		workdir: "/root"
		script: {
			directory: _sh.output
			filename:  "init.sh"
		}
	}
}
