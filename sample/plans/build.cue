package main
import (

	"alpha.dagger.io/os"
	"alpha.dagger.io/dagger/op"
	"alpha.dagger.io/docker"
)

build: {}

image: os.#Container & {
	image: docker.#Pull & {
		from: "ubuntu:latest"
	}
	dir: "/root"
	shell: path: "/bin/bash"
	command: #"""
echo "This is hello world from Heighliner."
sleep 10
"""#
}

check: {
	string

	#up: [
		op.#FetchContainer & {
			ref: "docker.io/lyzhang1999/alpine:v1"
		},

		op.#Exec & {
			args: [
				"/bin/bash",
				"--noprofile",
				"--norc",
				"-eo",
				"pipefail",
				"-c",
				#"""
					echo "This is hello world from Heighliner." >  /success
					"""#,
			]
			always: true
		},

		op.#Export & {
			source: "/success"
			format: "string"
		},
	]
} @dagger(output)