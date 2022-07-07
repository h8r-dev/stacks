package stack

import (
	// "dagger.io/dagger"
	"github.com/h8r-dev/stacks/chain/v3/internal/utils/echo"
)

#Install: {
	args: _
	_run: echo.#Run & {
		msg: "hello world"
	}
}
