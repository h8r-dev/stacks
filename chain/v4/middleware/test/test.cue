package test

import (
	"dagger.io/dagger"
	"github.com/h8r-dev/stacks/chain/v4/middleware"
)

dagger.#Plan & {
	actions: test: {
		args:        _
		_middleware: middleware.#Init & {
			"args": args
		}
	}
}
