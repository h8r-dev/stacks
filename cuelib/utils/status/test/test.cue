package status

import (
	"dagger.io/dagger"
	"universe.dagger.io/bash"
	"github.com/h8r-dev/stacks/cuelib/utils/status"
)

dagger.#Plan & {
	client: {
		commands: kubeconfig: {
			name: "cat"
			args: ["\(env.KUBECONFIG)"]
			stdout: dagger.#Secret
		}
		env: KUBECONFIG: string
	}

	actions: test: {
		run: status.#Status & {
			keyName:    "uuid"
			keyValue:   "1211"
			kubeconfig: client.commands.kubeconfig.stdout
		}

		output: bash.#Run & {
			input: run.output
			env: UUID: run.content
			script: contents: #"""
				    echo $UUID
				"""#
		}
	}
}
