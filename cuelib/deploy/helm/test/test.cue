package kubectl

import (
	"dagger.io/dagger"
	"github.com/h8r-dev/stacks/cuelib/deploy/helm"
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

	actions: test: helm.#Chart & {
		name:       "nocalhost"
		repository: "https://nocalhost.github.io/charts"
		chart:      "nocalhost"
		namespace:  "nocalhost"
		kubeconfig: client.commands.kubeconfig.stdout
	}
}
