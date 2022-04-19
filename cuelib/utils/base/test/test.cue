package random

import (
	"dagger.io/dagger"
	"universe.dagger.io/bash"
	"github.com/h8r-dev/stacks/cuelib/utils/base"
)

dagger.#Plan & {
	actions: {
		baseImage: base.#Kubectl & {
			version: "v1.23.5"
		}

		test: bash.#Run & {
			input:  baseImage.output
			always: true
			script: contents: #"""
				kubectl version --short --client
				"""#
		}
	}
}
