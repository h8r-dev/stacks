package main
import (

	"alpha.dagger.io/os"
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