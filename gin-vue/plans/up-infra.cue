package main

import (
	"dagger.io/dagger"
	"universe.dagger.io/alpine"
	"universe.dagger.io/bash"
	"universe.dagger.io/docker"
)

// Automatically setup infra resources:
//   Nocalhost, Loki, Granfana, Prometheus, ArgoCD

dagger.#Plan & {
	client: {
		filesystem: {
			"client.env.KUBECONFIG": read: contents: dagger.#FS
		}

		env: KUBECONFIG: string
	}

	actions: up: getIngressVersion: #GetIngressVersion & {
		kubeconfig: client.filesystem."client.env.KUBECONFIG".read.contents
	}
}

#GetIngressVersion: {
	kubeconfig: string

	// Get ingress version, such v1, v1beta1
	get: docker.#Build & {
		steps: [
			alpine.#Build & {
				packages: {
					bash: {}
					yarn: {}
					git: {}
				}
			},
			docker.#Copy & {
				contents: kubeconfig
				dest:     "/kubeconfig"
			},
			bash.#Run & {
				script: contents: #"""
					 ingress_result=$(kubectl --kubeconfig /kubeconfig api-resources --api-group=networking.k8s.io)
					 if [[ $ingress_result =~ "v1beta1" ]]; then
					  echo 'v1beta1' > /result
					 else
					  echo 'v1' > /result
					 fi
					"""#
			},
		]
	}
}
