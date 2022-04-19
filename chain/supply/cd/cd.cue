package cd

import (
	"github.com/h8r-dev/chain/supply/tools"
	"github.com/h8r-dev/chain/tools/argocd"
)

#Instance: {
	provider: "argocd": argocd

	input: #Input

	_install: tools.#Instance & {
		"input": tools.#Input & {
			kubeconfig: input.kubeconfig
			tools:
			[
				{
					name:    input.provider
					version: "v2.3.3"
					domain:  input.domain
				},
			]
			image: input.repositorys
		}
	}

	do: {
		// do provider init
		provider[input.provider].#Init & {
			"input": provider[input.provider].#Input & {
				kubeconfig: input.kubeconfig
				image:      _install.output.image
			}
		}
	}

	output: #Output & {
		image:   do.output.image
		success: do.output.success
	}
}
