package kubeconfig

import (
	"dagger.io/dagger/core"
	"universe.dagger.io/alpine"
	"universe.dagger.io/bash"
)

// TransformToInternal transforms the given kubeconfig to internal cluster address
#TransformToInternal: {
	input: #Input

	_baseImage: alpine.#Build & {
		packages: {
			bash: {}
			sed: {}
		}
	}

	_kubeconfig: input.kubeconfig

	transformToInternal: bash.#Run & {
		always:  true
		input:   _baseImage.output
		workdir: "/workspace"
		mounts: "KubeConfig Data": {
			dest:     "/kubeconfig"
			contents: _kubeconfig
		}
		script: contents: #"""
			set +ex
			cat /kubeconfig | sed -e 's?server: https://.*?server: https://kubernetes.default.svc?' > /result
			"""#
	}

	_getSecret: core.#NewSecret & {
		input: transformToInternal.output.rootfs
		path:  "/result"
	}

	output: #Output & {
		kubeconfig: _getSecret.output
	}
}
