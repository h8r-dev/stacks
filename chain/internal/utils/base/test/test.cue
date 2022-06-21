package random

import (
	"dagger.io/dagger"
	"github.com/h8r-dev/stacks/chain/internal/utils/base"
	"universe.dagger.io/bash"
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

		baseImageUbuntu: base.#Image & {}
		testBase:        bash.#Run & {
			input: baseImageUbuntu.output
			script: contents: #"""
				gh
				"""#
		}
	}
}
