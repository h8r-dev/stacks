package test

import (
	"dagger.io/dagger"
	"github.com/h8r-dev/stacks/chain/components/framework/next"
	"github.com/h8r-dev/stacks/chain/internal/utils/base"
	"universe.dagger.io/bash"
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
				echo "\n-------------------------------------\n"
				cat next.config.js
				echo "\n-------------------------------------\n"
				cat package.json
				"""
		}
	}
}
