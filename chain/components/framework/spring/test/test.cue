package test

import (
	"dagger.io/dagger"
	"universe.dagger.io/bash"
	"github.com/h8r-dev/chain/framework/spring"
	"github.com/h8r-dev/stacks/cuelib/utils/base"
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
