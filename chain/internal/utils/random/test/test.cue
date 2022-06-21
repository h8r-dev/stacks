package random

import (
	"dagger.io/dagger"
	"github.com/h8r-dev/stacks/chain/internal/utils/random"
	"universe.dagger.io/alpine"
	"universe.dagger.io/bash"
)

dagger.#Plan & {
	actions: {
		randomString: random.#String
		baseImage:    alpine.#Build & {
			packages: bash: {}
		}

		test: bash.#Run & {
			input:  baseImage.output
			always: true
			script: contents: #"""
				printf 'random string: \#(randomString.output)'
				"""#
		}
	}
}
