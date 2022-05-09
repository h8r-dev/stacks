package react

import (
	"dagger.io/dagger/core"
	"universe.dagger.io/bash"
	"universe.dagger.io/docker"
)

#Create: {
	// React Application name
	name: string

	// Create app command
	command: string

	dockerfile: core.#Source & {
		path: "dockerfile"
	}

	base: docker.#Pull & {
		source: "index.docker.io/node:lts-stretch"
	}

	run: docker.#Build & {
		steps: [
			bash.#Run & {
				input:   base.output
				workdir: "/root"
				always:  true
				env: APP_NAME:    name
				script: contents: #"""
					\#(command)
					"""#
			},
			docker.#Copy & {
				contents: dockerfile.output
				dest:     "/root/" + name + "/"
			},
		]
	}
	output: run.output
}
