package test

import (
	"dagger.io/dagger"
	"github.com/h8r-dev/stacks/chain/factory/toolsfactory"
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

	actions: test: toolsfactory.#Instance & {
		input: toolsfactory.#Input & {
			kubeconfig: client.commands.kubeconfig.stdout
			tools:
			[
				{
					name:    "argocd"
					version: "v2.3.3"
				},
				{
					name:    "nginx.kind"
					version: "helm-chart-4.0.19"
				},
			]
		}
	}
}
