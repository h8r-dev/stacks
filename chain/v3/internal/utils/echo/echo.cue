package echo

import (
	"dagger.io/dagger/core"
	"universe.dagger.io/bash"
	"github.com/h8r-dev/stacks/chain/v3/internal/base"
)

#Run: {
	msg: _

	_sh: core.#Source & {
		path: "."
		include: ["echo.sh"]
	}

	_deps: base.#Image

	bash.#Run & {
		input:  _deps.output
		always: true
		env: MESSAGE: msg
		script: {
			directory: _sh.output
			filename:  "echo.sh"
		}
	}
}
