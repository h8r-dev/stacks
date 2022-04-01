package main

import (
	"dagger.io/dagger"
	"universe.dagger.io/alpine"
	"universe.dagger.io/bash"
	// "universe.dagger.io/docker"
)

dagger.#Plan & {
	client: {
		filesystem: "output.yaml": write: contents: actions.up.readFile.contents
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
	}

	actions: up: {
		base: alpine.#Build & {
			packages: bash: {}
		}
		run: bash.#Run & {
			input:  base.output
			always: true
			env: {
				KC: client.env.KUBECONFIG
				AN: client.env.APP_NAME
				OG: client.env.ORGANIZATION
				GT: client.env.GITHUB_TOKEN
			}
			script: contents: #"""
				echo kubeconfig: $KC >> /result.yaml
				echo applicationname: $AN >> /result.yaml
				echo organization: $OG >> /result.yaml
				echo githubtoken: $GT >> /result.yaml
				"""#
		}
		readFile: dagger.#ReadFile & {
			input: run.output.rootfs
			path:  "/result.yaml"
		}
		output: readFile.contents
	}
}
