package main

import (
	"alpha.dagger.io/dagger"
	"alpha.dagger.io/os"
)

hello: {

	message: dagger.#Input & {string}

	createContainer: os.#Container & {
		command: """
			echo $MESSAGE > /tmp/out
			"""
		env: MESSAGE: message
	}

	createFile: os.#File & {
		from: createContainer
		path: "/tmp/out"
	}

	outputMessage: createFile.contents & dagger.#Output
}
