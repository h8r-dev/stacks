package test

import (
	"dagger.io/dagger"
	"github.com/h8r-dev/chain/ingress/nginx/kind"
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

	actions: test: kind.#Instance & {
		input: kind.#Input & {
			kubeconfig: client.commands.kubeconfig.stdout
			version:    "helm-chart-4.0.19"
		}
	}
}
