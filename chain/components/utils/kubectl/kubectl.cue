package kubectl

import (
	"dagger.io/dagger/core"
	"universe.dagger.io/bash"
	"universe.dagger.io/docker"
	"github.com/h8r-dev/stacks/chain/internal/utils/base"
)

#CreateNamespace: {
	namespace: string
	image:     docker.#Image

	valuePath: "/tmp/namespace.txt"

	run: bash.#Run & {
		input: image
		env: {
			NAMESPACE: namespace
			VALUEPATH: valuePath
		}
		script: contents: """
			  echo "Creating namespace $NAMESPACE"
			  kubectl create namespace $NAMESPACE > /dev/null 2>&1 || true
			  echo $NAMESPACE > $VALUEPATH
			"""
	}

	value: core.#ReadFile & {
		input: run.output.rootfs
		path:  valuePath
	}
}
