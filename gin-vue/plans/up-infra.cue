package main

import (
	"dagger.io/dagger"
	"universe.dagger.io/alpine"
	"universe.dagger.io/bash"
	"universe.dagger.io/docker"
)

// Automatically setup infra resources:
//   Nocalhost, Loki, Granfana, Prometheus, ArgoCD

#Kubectl: {
	version: string | *"v1.23.5"
	image:   docker.#Build & {
		steps: [
			alpine.#Build & {
				packages: {
					bash: {}
					curl: {}
				}
			},
			bash.#Run & {
				workdir: "/src"
				script: contents: #"""
					curl -LO https://dl.k8s.io/release/\#(version)/bin/linux/amd64/kubectl
					chmod +x kubectl
					mv kubectl /usr/local/bin/
					"""#
			},
		]
	}
}

_kubectl: #Kubectl & {version: "v1.23.5"}
kubectl: _kubectl.image.output

dagger.#Plan & {
	client: env: KUBECONFIG_DATA: dagger.#Secret

	// Get ingress version, such v1, v1beta1
	actions: getIngressVersion: bash.#Run & {
		input:   kubectl
		workdir: "/src"
		mounts: "KubeConfig Data": {
			dest:     "/kubeconfig"
			contents: client.env.KUBECONFIG_DATA
		}
		script: contents: #"""
			ingress_result=$(kubectl --kubeconfig /kubeconfig api-resources --api-group=networking.k8s.io)
			if [[ $ingress_result =~ "v1beta1" ]]; then
			 echo 'v1beta1' > /result
			else
			 echo 'v1' > /result
			fi
			"""#
	}
}
