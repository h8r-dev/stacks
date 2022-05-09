package random

import (
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

	run: bash.#Run & {
		input:  baseImage.output
		always: true
		env: SEED:        seed
		script: contents: #"""
			cat > /random-string.py <<"EOF"
			import random
			import string
			import os
			letters = string.ascii_lowercase
			print ( ''.join(random.choice(letters) for i in range(\#(length))) )
			EOF
			printf "$(python3 /random-string.py)" > /rand
			"""#
		export: files: "/rand": string
	}

	output: run.export.files."/rand"
}
