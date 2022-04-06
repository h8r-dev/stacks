package kubectl

import (
	"strconv"
	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"universe.dagger.io/bash"
	"universe.dagger.io/docker"
	"github.com/h8r-dev/cuelib/base"
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
		kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
		kubectl create secret docker-registry $SECRETNAME \
		--docker-server=$SERVER \
		--docker-username=$USERNAME \
		--docker-password=$(cat /run/secrets/github) \
		--namespace $NAMESPACE \
		-o yaml --dry-run=client | kubectl apply -f -
		mkdir /output
		"""#

	_kubectl: base.#Kubectl

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
			NAMESPACE:  namespace
		}
		always: true
		script: contents: #code
	}
}

// Apply Kubernetes manifest resource
#Manifest: {
	// Kubernetes manifest to deploy inlined in a string
	manifest: *null | string

	// Kubernetes Namespace to deploy to
	namespace: string | *"default"

	// Kube config file
	kubeconfig: string | dagger.#Secret

	kubectlImage: base.#Kubectl

	waitFor: bool | *true

	run: docker.#Run & {
		input: kubectlImage.output
		command: {
			name: "sh"
			flags: "-c": #"""
			mkdir /source
			printf '\#(manifest)' > /source/k8s.yaml
			cat /source/k8s.yaml
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

	// run: bash.#Run & {
	//  input: kubectlImage.output
	//  script: contents:
	//   mounts: {
	//    "kubeconfig": {
	//     dest:     "/etc/kubernetes/config"
	//     contents: kubeconfig
	//    }
	//    // "shell": {
	//    //  dest:     "/shell"
	//    //  contents: writeSH.output
	//    // }
	//    // if manifest != null {
	//    //  "source": {
	//    //   dest:     "/source"
	//    //   contents: writeYaml.output
	//    //  }
	//    // }
	//   }
	//  env: {
	//   KUBECONFIG:     "/etc/kubernetes/config"
	//   KUBE_NAMESPACE: namespace
	//  }
	//  always: true
	// }

	output: run.output

	success: run.success
}

// Apply Kubernetes resources
#Apply: {
	// Kubernetes manifest to deploy inlined in a string
	manifest: string | *null

	// Kubernetes manifest url to deploy remote configuration
	url: *null | string

	// Kubernetes Namespace to deploy to
	namespace: string | *"default"

	// Kube config file
	kubeconfig: string | dagger.#Secret

	waitFor: bool | *true

	code: #"""
		kubectl create namespace "$KUBE_NAMESPACE"  > /dev/null 2>&1 || true
		#if [ -d /source ] || [ -f /source ]; then
		#	kubectl --namespace "$KUBE_NAMESPACE" apply -R -f /source
		#	exit 0
		#fi
		if [ -n "$DEPLOYMENT_URL" ]; then
			kubectl --namespace "$KUBE_NAMESPACE" apply -R -f "$DEPLOYMENT_URL"
			exit 0
		fi
		"""#

	kubectlImage: base.#Kubectl

	_writeSH: core.#WriteFile & {
		input:       dagger.#Scratch
		path:        "/run.sh"
		contents:    code
		permissions: 0o755
	}

	_writeOutput: _writeSH.output

	run: bash.#Run & {
		input: kubectlImage.output
		script: contents: #"""
			sh /shell/run.sh
			"""#
		mounts: {
			"kubeconfig": {
				dest:     "/etc/kubernetes/config"
				contents: kubeconfig
			}
			shell: {
				dest:     "/shell"
				contents: _writeOutput
			}
		}
		env: {
			KUBECONFIG:     "/etc/kubernetes/config"
			KUBE_NAMESPACE: namespace
			if url != null {
				DEPLOYMENT_URL: url
			}
			WAIT_FOR: strconv.FormatBool(waitFor)
		}
		always: true
	}

	output: run.output

	success: run.success
}
