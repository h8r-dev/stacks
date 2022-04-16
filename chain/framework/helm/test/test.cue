package test

import (
	"dagger.io/dagger"
	"universe.dagger.io/bash"
	"github.com/h8r-dev/chain/framework/helm"
	"github.com/h8r-dev/cuelib/utils/base"
)

dagger.#Plan & {
	actions: {
		_baseImage: base.#Image & {}
		build:      helm.#Instance & {
			input: helm.#Input & {
				name:  "docs-deploy"
				image: _baseImage.output
				set: """
					'.image.repository = "rep" | .image.tag = "tag"'
					"""
			}
		}
		test: bash.#Run & {
			input: build.output.image
			script: contents: """
				cd /scaffold/docs-deploy
				cat values.yaml
				"""
		}
	}
}
