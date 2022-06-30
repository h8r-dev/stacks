package test

import (
	"dagger.io/dagger"
	"universe.dagger.io/bash"
	"github.com/h8r-dev/stacks/chain/addons/nocalhost"
	"github.com/h8r-dev/stacks/chain/internal/utils/base"
)

dagger.#Plan & {
	actions: {
		_baseImage: base.#Image & {}
		build:      nocalhost.#Instance & {
			input: nocalhost.#Input & {
				image:    _baseImage.output
				helmName: "docs-deploy"
			}
		}
		test: bash.#Run & {
			input: build.output.image
			script: contents: """
				cd /scaffold/docs-deploy
				ls
				"""
		}
	}
}
