package next

import (
	"universe.dagger.io/docker"
	"universe.dagger.io/bash"
	"dagger.io/dagger/core"
	//"github.com/h8r-dev/stacks/cuelib/framework/react/next"
	"strconv"
)

#Instance: {
	input: #Input

	// _build: next.#Create & {
	//  name: input.name
	// }
	// _outputFramework: core.#Subdir & {
	//  "input": _build.output.rootfs
	//  path:    "/root/\(input.name)"
	// }
	// _rewrite: core.#Source & {
	//  path: "template"
	// }
	// _beforeRewriteBaseImage: docker.#Copy & {
	//  "input":  input.image
	//  contents: _outputFramework.output
	//  dest:     "/scaffold/\(input.name)"
	// }
	// do: docker.#Copy & {
	//  "input":  _beforeRewriteBaseImage.output
	//  contents: _rewrite.output
	//  dest:     "/scaffold/\(input.name)"
	// }

	_build: bash.#Run & {
		"input": input.image
		workdir: "/scaffold"
		env: {
			APP_NAME:   input.name
			TYPESCRIPT: strconv.FormatBool(input.typescript)
		}
		script: contents: #"""
			yarn config set registry http://mirrors.cloud.tencent.com/npm/
			OPTS=""
			[ "$TYPESCRIPT" = "true" ] && OPTS="$OPTS --typescript"
			echo "$APP_NAME" | yarn create next-app $OPTS
			"""#
	}
	_file: core.#Source & {
		path: "template"
	}
	do: docker.#Copy & {
		"input":  _build.output
		contents: _file.output
		dest:     "/scaffold/\(input.name)"
	}

	output: #Output & {
		image: do.output
	}
}
