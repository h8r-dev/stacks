package gin

import (
	"dagger.io/dagger/core"
	"universe.dagger.io/bash"
	"universe.dagger.io/docker"
)

#Config: {
	addons: [...]
	for idx, addon in addons {
		(addon.name): _#execConfig & {
			"name": addon.name
		}
	}
}

_#execConfig: {
	name:  _
	_deps: docker.#Pull & {
		source: "lyzhang1999/ubuntu:latest@sha256:d265807ca17db2610100b102ccbfa285ae73c78e5666078508d20d1415e3c01c"
	}
	_sh: core.#Source & {
		path: "."
		include: ["config.sh"]
	}
	bash.#Run & {
		always:  true
		input:   _deps.output
		workdir: "/root"
		env: ADDON: name
		script: {
			directory: _sh.output
			filename:  "config.sh"
		}
	}
}
