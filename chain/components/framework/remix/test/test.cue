package test

import (
	"dagger.io/dagger"
	"github.com/h8r-dev/stacks/chain/components/framework/remix"
	"github.com/h8r-dev/stacks/chain/internal/utils/base"
	"universe.dagger.io/bash"
)

dagger.#Plan & {
	actions: {
		_baseImage: base.#Image & {}

		appName: "remix-fullstack-app"

		_build: remix.#Instance & {
			input: remix.#Input & {
				name:  appName
				image: _baseImage.output
			}
		}

		test: bash.#Run & {
			input:  _build.output.image
			always: true
			script: contents: """
        cd /scaffold/\(appName)
        ls -alh
      """
		}
	}
}
