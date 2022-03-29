package kubectl

import (
	"dagger.io/dagger"
	"universe.dagger.io/bash"
)

// Apply Kubernetes resources
#Apply: {

	// Kubernetes manifest to deploy inlined in a string
	manifest: string

	// Kubernetes manifest url to deploy remote configuration
	// url?: string

	// Kubernetes Namespace to deploy to
	namespace: string | *"default"

	// Version of kubectl client
	version: string | *null

	// Kube config file
	kubeconfig: string | dagger.#Secret

	_kubectlImage: #Kubectl

	write: dagger.#WriteFile & {
		input:    dagger.#Scratch
		path:     "/k8s.yaml"
		contents: manifest
	}

	run: bash.#Run & {
		input:  _kubectlImage.output
		always: true
		mounts: {
			"kubeconfig": {
				dest:     "/etc/kubernetes/config"
				contents: kubeconfig
			}
			"yaml source": {
				dest:     "/source"
				contents: write.output
			}
		}
		env: {
			KUBECONFIG:     "/etc/kubernetes/config"
			KUBE_NAMESPACE: namespace
		}
		script: contents: #"""
			kubectl create namespace "$KUBE_NAMESPACE"  > /dev/null 2>&1 || true
			if [ -d /source ] || [ -f /source ]; then
				kubectl --namespace "$KUBE_NAMESPACE" apply -R -f /source
				exit 0
			fi
			#if [ -n "$DEPLOYMENT_URL" ]; then
			#	kubectl --namespace "$KUBE_NAMESPACE" apply -R -f "$DEPLOYMENT_URL"
			#	exit 0
			#fi
			"""#
	}
}
