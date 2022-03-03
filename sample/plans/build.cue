package main
import (
	"alpha.dagger.io/dagger"
	"alpha.dagger.io/os"
)

hello: {

	message: dagger.#Input & {string}

	container: os.#Container & {
		command: """
			echo $MESSAGE > /tmp/out
			"""
		env: {
			MESSAGE: message
		}
	}

	file: os.#File & {
		from: container
		path: "/tmp/out"
	}

	output: file.contents & dagger.#Output
}