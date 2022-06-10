package gin

import (
	"dagger.io/dagger/core"
	"universe.dagger.io/bash"
	"universe.dagger.io/docker"
)

#Init: {
	sourceCode: "printf(hello world)"
	_deps:      docker.#Pull & {
		source: "heighlinerdev/stack-base:debian"
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
