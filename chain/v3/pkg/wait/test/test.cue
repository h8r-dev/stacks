package test

import (
	"dagger.io/dagger"
	"universe.dagger.io/docker"
	"github.com/h8r-dev/stacks/chain/v3/pkg/wait"
	"github.com/h8r-dev/stacks/chain/v3/internal/base"

)

dagger.#Plan & {
	actions: {
		_baseImage: base.#Image

		_run1: docker.#Run & {
			input: _baseImage.output
			command: {
				name: "sh"
				flags: "-c": #"""
					echo run 1
					"""#
			}
		}

		_run2: docker.#Run & {
			input: _baseImage.output
			command: {
				name: "sh"
				flags: "-c": #"""
					echo run 2
					"""#
			}
		}

		_run3: docker.#Run & {
			input: _baseImage.output
			command: {
				name: "sh"
				flags: "-c": #"""
					echo run 3
					"""#
			}
		}

		test: wait.#List & {
			list: [_run1.success, _run2.success, _run3.success]
			name: "test"
		}

	}
}
