package random

import (
	"dagger.io/dagger"
	"universe.dagger.io/alpine"
	"universe.dagger.io/bash"
	"github.com/h8r-dev/stacks/cuelib/utils/random"
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
