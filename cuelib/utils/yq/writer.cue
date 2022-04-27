package yq

import (
	"universe.dagger.io/docker"
)

// Input key-value pairs amd output yaml file
// The keys should follow yq syntax:
// https://github.com/mikefarah/yq
#Writer: {
	values: [string]: string

	output: fetch.export.files."/tmp/output.yaml"

	run: docker.#Build & {
		steps: [
			docker.#Pull & {
				source: "index.docker.io/mikefarah/yq"
			},
			docker.#Run & {
				entrypoint: ["/bin/sh"]
				command: {
					name: "-c"
					args: ["touch /tmp/output.yaml"]
				}
			},
			for key, value in values {
				docker.#Run & {
					env: {
						VALUE: value
					}
					entrypoint: ["/bin/sh"]
					command: {
						name: "-c"
						args: [" yq -i '\(key) = strenv(VALUE)' /tmp/output.yaml"]
					}
				}
			},
		]
	}
	fetch: docker.#Run & {
		input: run.output
		export: files: "/tmp/output.yaml": string
	}
}
