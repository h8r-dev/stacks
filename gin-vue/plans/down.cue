package main

import (
	"dagger.io/dagger"
)

dagger.#Plan & {
	client: env: KUBECONFIG_DATA: dagger.#Secret

	actions: deleteNocalhost: #DeleteChart & {
		releasename: "nocalhost"
		kubeconfig:  client.env.KUBECONFIG_DATA
	}
}
