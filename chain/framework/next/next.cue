package next

import (
	"universe.dagger.io/docker"
	"dagger.io/dagger/core"
	"github.com/h8r-dev/cuelib/framework/react/next"
)

#Instance: {
	input:  #Input
	_build: next.#Create & {
		name: input.name
	}
	_outputFramework: core.#Subdir & {
		"input": _build.output.rootfs
		path:    "/root/\(input.name)"
	}
	_rewrite: core.#Source & {
		path: "template"
	}
	_beforeRewriteBaseImage: docker.#Copy & {
		"input":  input.image
		contents: _outputFramework.output
		dest:     "/scaffold/\(input.name)"
	}
	do: docker.#Copy & {
		"input":  _beforeRewriteBaseImage.output
		contents: _rewrite.output
		dest:     "/scaffold/\(input.name)"
	}
	output: #Output & {
		image: do.output
	}
}
