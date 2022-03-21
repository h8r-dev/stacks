package main

// Automatically setup infra resources:
//   Nocalhost, Loki, Granfana, Prometheus, ArgoCD

dagger.#Plan & {
	client: {
		filesystem: "output/": write: contents: actions.up.getIngressVersion.get

		env: KUBECONFIG_DATA: dagger.#Secret
	}

	actions: up: getIngressVersion: #GetIngressVersion & {
	}
}

#GetIngressVersion: {
	// Get ingress version, such v1, v1beta1
	get: "TODO"
}
