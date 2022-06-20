package wait

import (
	"universe.dagger.io/docker"
	"github.com/h8r-dev/stacks/chain/v3/internal/base"
)

#List: {
	list: [...bool]
	name: string

	_deps: base.#Image

	docker.#Run & {
		input: _deps.output
		_name: name
		env: {
			for idx, e in list {
				"\(idx)": "\(e)"
			}
		}
		command: {
			name: "sh"
			flags: "-c": """
				echo "wait for \(_name)"
				"""
		}
	}
}
