package kubectl

import (
	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"universe.dagger.io/bash"
	"universe.dagger.io/docker"
)

#CreateNamespace: {
	kubeconfig: dagger.#Secret
	namespace:  string
	image:      docker.#Image

	valuePath: "/tmp/namespace.txt"

	run: bash.#Run & {
		input: image
		env: {
			NAMESPACE: namespace
			VALUEPATH: valuePath
		}
		mounts: "kubeconfig": {
			dest:     "/root/.kube/config"
			type:     "secret"
			contents: kubeconfig
		}
		script: contents: """
			    echo "Creating namespace: $NAMESPACE"
			    kubectl create namespace $NAMESPACE > /dev/null 2>&1 || true
			    printf $NAMESPACE > $VALUEPATH
			"""
	}

	value: core.#ReadFile & {
		input: run.output.rootfs
		path:  valuePath
	}

	success: run.success
}
