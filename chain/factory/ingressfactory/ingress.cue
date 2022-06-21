package ingressfactory

import (
	nginxCloud "github.com/h8r-dev/stacks/chain/components/ingress/nginx/cloud"
	nginxKind "github.com/h8r-dev/stacks/chain/components/ingress/nginx/kind"
	"universe.dagger.io/docker"
)

#Instance: {
	tools: {
		"nginx.kind":  nginxKind
		"nginx.cloud": nginxCloud
	}

	input: #Input

	do: {
		for idx, i in input.tools {
			"\(idx)": tools[i.name].#Instance & {
				_output: docker.#Image
				if idx == 0 {
					_output: input.image
				}
				if idx > 0 {
					_output: do["\(idx-1)"].output.image
				}
				"input": tools[i.name].#Input & {
					kubeconfig: input.kubeconfig
					version:    i.version
					image:      _output
					domain:     i.domain
				}
			}
		}
	}

	if len(do) > 0 {
		output: #Output & {
			image: do["\(len(do)-1)"].output.image
		}
	}
}
