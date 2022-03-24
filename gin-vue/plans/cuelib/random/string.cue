package random

import (
	"dagger.io/dagger"
	"universe.dagger.io/alpine"
	"universe.dagger.io/bash"
)

// https://github.com/dagger/dagger/blob/v0.1.0/pkg/alpha.dagger.io/random/string.cue
#String: {
	length: string | *"6"
	seed:   string | *""
	output: string

	baseImage: alpine.#Build & {
		packages: {
			bash: {}
			python3: {}
		}
	}

	write: dagger.#WriteFile & {
		input:    dagger.#Scratch
		path:     "/entrypoint.py"
		contents: #"""
			import random
			import string
			import os
			letters = string.ascii_lowercase
			print ( ''.join(random.choice(letters) for i in range(\#(length))) )
			"""#
	}

	run: bash.#Run & {
		input:  baseImage.output
		always: true
		mounts: "Python scripts": {
			contents: write.output
			dest:     "/py/scripts"
		}
		env: SEED: seed
		script: contents: #"""
			printf "$(python3 /py/scripts/entrypoint.py)" > /rand
			"""#
		export: files: "/rand": string
	}

	output: run.export.files."/rand"
}
