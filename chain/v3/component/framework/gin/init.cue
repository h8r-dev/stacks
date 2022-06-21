package gin

import (
	"dagger.io/dagger"
	"dagger.io/dagger/core"
	// "github.com/h8r-dev/stacks/chain/v3/internal/base"
	// "universe.dagger.io/bash"
	// "universe.dagger.io/docker"
)

#Init: {

	output: sourceCode: dagger.#FS

	output: sourceCode: _sourceCode.output

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
