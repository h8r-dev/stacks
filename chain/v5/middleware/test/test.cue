package test

import (
	"dagger.io/dagger"
	"github.com/h8r-dev/stacks/chain/v5/middleware"
)

dagger.#Plan & {
	actions: test: {
		args:        _
		_middleware: middleware.#Init & {
			"args": args
		}
	}
}
