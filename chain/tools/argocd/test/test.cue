package test

import (
	"dagger.io/dagger"
	"github.com/h8r-dev/chain/argocd"
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

	actions: test: argocd.#Instance & {
		input: argocd.#Input & {
			kubeconfig: client.commands.kubeconfig.stdout
			version:    "v2.3.3"
		}
	}
}
