package test

import (
	"dagger.io/dagger"
	"universe.dagger.io/bash"
	"github.com/h8r-dev/chain/framework/next"
	"github.com/h8r-dev/cuelib/utils/base"
)

dagger.#Plan & {
	actions: {
		_baseImage: base.#Image & {}
		build:      next.#Instance & {
			input: next.#Input & {
				name:  "docs-frontend"
				image: _baseImage.output
			}
		}
		test: bash.#Run & {
			input:  build.output.image
			always: true
			script: contents: """
				cd /scaffold/docs-frontend
				ls
				cat Dockerfile
				cat next.config.js
				"""
		}
	}
}
