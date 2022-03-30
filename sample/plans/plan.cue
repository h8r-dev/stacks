package main

import (
	"dagger.io/dagger"
	"universe.dagger.io/alpine"
	"universe.dagger.io/bash"
	"universe.dagger.io/docker"
)

dagger.#Plan & {
	client: {
		commands: kubeconfig: {
			name: "cat"
			args: ["\(env.KUBECONFIG)"]
			stdout: dagger.#Secret
		}
		env: {
			KUBECONFIG:   string
			APP_NAME:     string
			ORGANIZATION: string
			GITHUB_TOKEN: dagger.#Secret
		}
		filesystem: output: write: contents: actions.up.run.export.files["/result"]
	}

	actions: up: #Action
}

#Action: {
	image: docker.#Build & {
		steps: [
			alpine.#Build & {
				packages: {
					bash: {}
					curl: {}
				}
			},
		]
	}
	run: bash.#Run & {
		input: image.output
		script: contents: #"""
			echo result of your actions > /result
			"""#
		export: files: "/result": string
	}
}
