package kubectl

import (
	"dagger.io/dagger"
	"strconv"
	"dagger.io/dagger/core"
	"github.com/h8r-dev/stacks/chain/internal/utils/base"
	"universe.dagger.io/bash"
	"universe.dagger.io/docker"
)

#CreateImagePullSecret: {
	// Kube config file
	kubeconfig: dagger.#Secret

	// Image pull username
	username: string

	// Image pull password
	password: dagger.#Secret

	// Image pull secret name
	secretName: *"h8r-secret" | string

	// Server url
	server: *"ghcr.io" | string

	// Namespace
	namespace: string

	#code: #"""
		for NAMESPACE in ${NAMESPACES[@]}; do
			kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
			kubectl create secret docker-registry $SECRETNAME \
			--docker-server=$SERVER \
			--docker-username=$USERNAME \
			--docker-password=$(cat /run/secrets/github) \
			--namespace $NAMESPACE \
			-o yaml --dry-run=client | kubectl apply -f -
		done
		"""#

	_kubectl: base.#Image

	run: bash.#Run & {
		input: _kubectl.output
		mounts: "kubeconfig": core.#Mount & {
			dest:     "/kubeconfig"
			type:     "secret"
			contents: kubeconfig
		}
		mounts: github: core.#Mount & {
			dest:     "/run/secrets/github"
			type:     "secret"
			contents: password
		}
		env: {
			KUBECONFIG: "/kubeconfig"
			USERNAME:   username
			SECRETNAME: secretName
			SERVER:     server
			NAMESPACES: namespace
		}
		always: true
		script: contents: #code
	}
}

// Apply Kubernetes manifest resource
#Manifest: {
	// Kubernetes manifest to deploy inlined in a string
	manifest: string

	// Kubernetes Namespace to deploy to
	namespace: string | *"default"

	// Kube config file
	kubeconfig: string | dagger.#Secret

	_kubectlImage: base.#Image

	waitFor: bool | *true

	run: docker.#Run & {
		input: _kubectlImage.output
		command: {
			name: "sh"
			flags: "-c": #"""
			mkdir /source
			printf '\#(manifest)' > /source/k8s.yaml
			# cat /source/k8s.yaml
			kubectl create namespace "$KUBE_NAMESPACE"  > /dev/null 2>&1 || true
			if [ -d /source ] || [ -f /source ]; then
				kubectl --namespace "$KUBE_NAMESPACE" apply -R -f /source
				exit 0
			fi
			"""#
		}
		mounts: "kubeconfig": {
			dest:     "/etc/kubernetes/config"
			contents: kubeconfig
		}
		env: {
			WAIT_FOR:       strconv.FormatBool(waitFor)
			KUBECONFIG:     "/etc/kubernetes/config"
			KUBE_NAMESPACE: namespace
		}
		always: true
	}

	output: run.output

	success: run.success
}

// Apply Kubernetes resources
#Apply: {
	// Kubernetes manifest url to deploy remote configuration
	url: string

	// Kubernetes Namespace to deploy to
	namespace: string

	// Kube config file
	kubeconfig: string | dagger.#Secret

	waitFor: bool | *true

	_kubectlImage: base.#Image

	run: bash.#Run & {
		input: _kubectlImage.output
		script: contents: #"""
			kubectl create namespace "$KUBE_NAMESPACE"  > /dev/null 2>&1 || true
			if [ -n "$DEPLOYMENT_URL" ]; then
				kubectl --namespace "$KUBE_NAMESPACE" apply -R -f "$DEPLOYMENT_URL"
				exit 0
			fi
			"""#
		mounts: "kubeconfig": {
			dest:     "/etc/kubernetes/config"
			contents: kubeconfig
		}
		env: {
			KUBECONFIG:     "/etc/kubernetes/config"
			KUBE_NAMESPACE: namespace
			DEPLOYMENT_URL: url
			WAIT_FOR:       strconv.FormatBool(waitFor)
		}
		always: true
	}

	output: run.output

	success: run.success
}
