package random

import (
	"universe.dagger.io/alpine"
	"universe.dagger.io/bash"
)

#String: {
	length: string | *"6"
	output: string

	baseImage: alpine.#Build & {
		packages: bash: {}
	}

	run: bash.#Run & {
		input: baseImage.output
		script: contents: #"""
			head /dev/urandom | tr -dc a-z | head -c \#(length) > output.txt
			"""#
		export: files: "/output.txt": string
	}

	output: run.export.files."/output.txt"
}
