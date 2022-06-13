package test

import (
	"dagger.io/dagger"
	"universe.dagger.io/bash"
	"github.com/h8r-dev/stacks/chain/components/infra/prometheus"
	"github.com/h8r-dev/stacks/chain/internal/utils/base"
)

dagger.#Plan & {
	actions: {
		_baseImage: base.#Image & {}
		build:      prometheus.#Instance & {
			input: prometheus.#Input & {
				image:    _baseImage.output
				helmName: "docs-deploy"
				// networkType: "default"
				networkType: "cn"
			}
		}
		test: bash.#Run & {
			input: build.output.image
			script: contents: """
				cd /scaffold/docs-deploy
				ls -alh
				cat ./infra/prometheus-stack/values.yaml
				"""
		}
	}
}
