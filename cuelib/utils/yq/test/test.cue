package yq

import (
	"dagger.io/dagger"
	"github.com/h8r-dev/stacks/cuelib/utils/yq"
)

dagger.#Plan & {
	actions: test: yq.#Writer & {
		values: ".a.b[0].c": #"""
			hello
			world
			"""#
		output: #"""
			a:
			  b:
			    - c: |-
			        hello
			        world
			
			"""#
	}
}
