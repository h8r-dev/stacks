package gin

import (
	"dagger.io/dagger/core"
	// "universe.dagger.io/bash"
	// "universe.dagger.io/docker"

	// "github.com/h8r-dev/stacks/cuelib/internal/utils/base"
)

#Init: {

	sourceCode: _sourceCode.output

	_sourceCode: core.#Source & {
		path: "template"
	}

	// Maybe generate dynamically source codes in future

	// _deps: docker.#Build & {
	//  steps: [
	//   base.#Image,
	//   docker.#Copy & {
	//    contents: _sourceCode.output
	//    dest:     "/workdir/source"
	//   },
	//  ]
	// }

	// _sh: core.#Source & {
	//  path: "."
	//  include: ["init.sh"]
	// }

	// bash.#Run & {
	//  always:  true
	//  input:   _deps.output
	//  workdir: "/workdir"
	//  script: {
	//   directory: _sh.output
	//   filename:  "init.sh"
	//  }
	// }
}
