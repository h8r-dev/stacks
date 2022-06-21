package cdfactory

import (
	"github.com/h8r-dev/stacks/chain/components/cd/argocd"
	//"github.com/h8r-dev/stacks/chain/factory/ingressfactory"
)

#Instance: {
	provider: "argocd": argocd

	input: #Input

	_install: provider[input.provider].#Instance & {
		"input": provider[input.provider].#Input & {
			kubeconfig: input.kubeconfig
			version:    "v2.3.3"
			image:      input.repositorys
			domain:     input.domain
		}
	}

	do: {
		// do provider init
		provider[input.provider].#Init & {
			"input": provider[input.provider].#Input & {
				kubeconfig: input.kubeconfig
				image:      _install.output.image
				domain:     input.domain
			}
		}
	}

	output: #Output & {
		image:   do.output.image
		success: do.output.success
	}
}
