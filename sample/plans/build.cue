package main
import (
	"alpha.dagger.io/dagger"
	"alpha.dagger.io/os"
)

hello: {

	message: dagger.#Input & {string}

	ctr: os.#Container & {
		command: """
			echo $MESSAGE > /tmp/out
			"""
		env: {
			MESSAGE: message
		}
	}

	f: os.#File & {
		from: ctr
		path: "/tmp/out"
	}

	response: f.contents & dagger.#Output
}