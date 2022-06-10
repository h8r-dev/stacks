package next

import (
	"dagger.io/dagger/core"
	"universe.dagger.io/bash"

	"github.com/h8r-dev/stacks/cuelib/internal/utils/base"
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
	name: _

	_baseImage: base.#Image

	_sh: core.#Source & {
		path: "."
		include: ["config.sh"]
	}
	bash.#Run & {
		always:  true
		input:   _baseImage.output
		workdir: "/root"
		env: ADDON: name
		script: {
			directory: _sh.output
			filename:  "config.sh"
		}
	}
}
