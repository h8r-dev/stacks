package test

import (
	"dagger.io/dagger"
	"github.com/h8r-dev/stacks/chain/addons/prometheus"
	"github.com/h8r-dev/stacks/chain/internal/utils/base"
	"universe.dagger.io/bash"
)

dagger.#Plan & {
	actions: {
		_baseImage: base.#Image & {}
		build:      prometheus.#Instance & {
			input: prometheus.#Input & {
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
