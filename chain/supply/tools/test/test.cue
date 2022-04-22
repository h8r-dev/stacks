package test

import (
	"dagger.io/dagger"
	"github.com/h8r-dev/chain/supply/tools"
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

	actions: test: tools.#Instance & {
		input: tools.#Input & {
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
