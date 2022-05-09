package github

import (
	"universe.dagger.io/bash"
	"dagger.io/dagger/core"
	"dagger.io/dagger"
)

#Instance: {
	input: #Input

	_writeYaml: output: core.#FS

	_writeYaml: core.#WriteFile & {
		"input":  dagger.#Scratch
		path:     "docker-publish.yml"
		contents: input.action
	}

	_writeYamlOutput: _writeYaml.output

	do: bash.#Run & {
		"input": input.image
		mounts: helm: {
			contents: _writeYamlOutput
			dest:     "/h8r/ci/\(input.name)"
		}
		script: contents: """
				mkdir -p /scaffold/\(input.name)/.github/workflows
				mv /h8r/ci/\(input.name)/docker-publish.yml /scaffold/\(input.name)/.github/workflows/docker-publish.yml
				echo 'github action workflows added'
			"""
	}
	output: #Output & {
		image: do.output
	}
}
