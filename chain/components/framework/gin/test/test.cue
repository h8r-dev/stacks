package test

import (
	"dagger.io/dagger"
	"universe.dagger.io/bash"
	"github.com/h8r-dev/stacks/chain/framework/gin"
	"github.com/h8r-dev/stacks/chain/internal/utils/base"
)

dagger.#Plan & {
	actions: {
		_baseImage: base.#Image & {}
		build:      gin.#Instance & {
			input: gin.#Input & {
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
