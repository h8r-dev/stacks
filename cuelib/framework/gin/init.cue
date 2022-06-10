package gin

import (
	"dagger.io/dagger/core"
	"universe.dagger.io/bash"

	"github.com/h8r-dev/stacks/cuelib/internal/utils/base"
)

#Init: {
	sourceCode: "printf(hello world)"

	_baseImage: base.#Image

	_sh: core.#Source & {
		path: "."
		include: ["init.sh"]
	}

	bash.#Run & {
		always:  true
		input:   _baseImage.output
		workdir: "/root"
		script: {
			directory: _sh.output
			filename:  "init.sh"
		}
	}
}
