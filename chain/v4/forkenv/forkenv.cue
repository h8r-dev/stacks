package forkenv

import (
	"github.com/h8r-dev/stacks/chain/v3/internal/utils/echo"
)

#Fork: {
	args: _

	_echo: echo.#Run & {
		msg: "deploy: " + args.deploy.name
	}
}
