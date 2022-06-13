package echo

import (
	"universe.dagger.io/bash"
	"dagger.io/dagger/core"
	"github.com/h8r-dev/stacks/cuelib/internal/base"
)

#Run: {
	msg: _

	_sh: core.#Source & {
		path: "."
		include: ["echo.sh"]
	}

	_deps: base.#Image

	bash.#Run & {
		input: _deps.output
		env: MESSAGE: msg
		script: {
			directory: _sh.output
			filename:  "echo.sh"
		}
	}
}
