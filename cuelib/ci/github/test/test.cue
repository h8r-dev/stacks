package github

import (
	"dagger.io/dagger"
	"github.com/h8r-dev/cuelib/ci/github"
	"universe.dagger.io/alpine"
	"universe.dagger.io/bash"
)

dagger.#Plan & {
	client: {

	}

	actions: test: {
		image: alpine.#Build & {
			packages: bash: _
		}

		run: github.#Create & {
			input: image.output
			path:  "test-app"
		}

		list: bash.#Run & {
			input:  run.output
			always: true
			script: contents: #"""
					cd /root/test-app
					ls -al
				"""#
		}
	}
}
