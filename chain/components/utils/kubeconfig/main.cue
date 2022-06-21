package kubeconfig

import (
	"dagger.io/dagger/core"
	"github.com/h8r-dev/stacks/chain/internal/utils/base"
	"universe.dagger.io/bash"
)

// TransformToInternal transforms the given kubeconfig to internal cluster address
#TransformToInternal: {
	input: #Input

	_baseImage: base.#Image

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
			server=$(kubectl config view --minify --kubeconfig /kubeconfig | awk '/server: /{print $2}')
			printf '%s' "$server" > /api_server
			cat /kubeconfig | sed -e 's?server: https://.*?server: https://kubernetes.default.svc?' > /result
			"""#
		export: files: "/api_server": string
	}

	_getSecret: core.#NewSecret & {
		input: transformToInternal.output.rootfs
		path:  "/result"
	}

	output: #Output & {
		kubeconfig: _getSecret.output
		apiServer:  transformToInternal.export.files."/api_server"
	}
}
