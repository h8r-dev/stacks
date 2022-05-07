package argocd

import (
	"dagger.io/dagger"
	"github.com/h8r-dev/stacks/chain/internal/cd/argocd"
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

	actions: test: argocd.#Install & {
		host:           "1.1.1.1"
		domain:         "argo-test.argocd.stack.h8r.io"
		ingressVersion: "v1"
		uri:            "argo-test"
		namespace:      "argocd"
		kubeconfig:     client.commands.kubeconfig.stdout
	}
}
