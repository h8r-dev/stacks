package test

import (
	"dagger.io/dagger"
	"github.com/h8r-dev/stacks/chain/components/framework/spring"
	"github.com/h8r-dev/stacks/cuelib/utils/base"
	"universe.dagger.io/bash"
)

dagger.#Plan & {
	actions: {
		_baseImage: base.#Image & {}
		build:      spring.#Instance & {
			input: spring.#Input & {
				name:  "docs"
				image: _baseImage.output
			}
		}
		test: bash.#Run & {
			input: build.output.image
			script: contents: """
				cd /scaffold/docs
				ls
				"""
		}
	}
}
