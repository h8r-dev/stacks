package test

import (
	"dagger.io/dagger"
	"universe.dagger.io/bash"
	"github.com/h8r-dev/chain/addons/loki"
	"github.com/h8r-dev/cuelib/utils/base"
)

dagger.#Plan & {
	actions: {
		_baseImage: base.#Image & {}
		build:      loki.#Instance & {
			input: loki.#Input & {
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
