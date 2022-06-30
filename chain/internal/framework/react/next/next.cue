package next

import (
	"strconv"
	"dagger.io/dagger/core"
	"universe.dagger.io/bash"
	"universe.dagger.io/docker"
)

#Create: {
	// Next Application name
	name: string

	// use typescript
	typescript: bool | *true

	dockerfile: core.#Source & {
		path: "dockerfile"
	}

	configFile: core.#Source & {
		path: "config"
	}

	base: docker.#Pull & {
		source: "index.docker.io/node:lts-stretch"
	}

	run: docker.#Build & {
		steps: [
			bash.#Run & {
				input:   base.output
				workdir: "/root"
				always:  false
				env: {
					APP_NAME:   name
					TYPESCRIPT: strconv.FormatBool(typescript)
				}
				script: contents: #"""
					yarn config set registry http://mirrors.cloud.tencent.com/npm/
					OPTS=""
					[ "$TYPESCRIPT" = "true" ] && OPTS="$OPTS --typescript"
					echo "$APP_NAME" | yarn create next-app $OPTS
					"""#
			},
			docker.#Copy & {
				contents: dockerfile.output
				dest:     "/root/" + name + "/"
			},
			docker.#Copy & {
				contents: configFile.output
				dest:     "/root/" + name + "/"
			},
		]
	}
	output: run.output
}
