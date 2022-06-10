package next

import (
	"dagger.io/dagger/core"
	"universe.dagger.io/bash"
	"universe.dagger.io/docker"
)

#Config: {
	addons: [...]
	for idx, addon in addons {
		(addon.name): _#execConfig & {
			name: addon.name
		}
	}
}

_#execConfig: {
	name:  _
	_deps: docker.#Pull & {
		source: "heighlinerdev/stack-base:debian"
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
