package cd

import (
	"github.com/h8r-dev/chain/supply/tools"
)

#Instance: {
	provider: {
		"argocd": argocd
	}

	input: #Input

	_install: tools.#Instance & {
		input: tools.#Input & {
			"kubeconfig": input.kubeconfig
			tools:
			[
				{
					name:    "argocd"
					version: "v2.3.3"
				},
			]
		}
	}

	do: {
		// provider[input.provider].#Instance & {
		//  "input": provider[input.provider].#Input & {
		//   personalAccessToken: input.personalAccessToken
		//   organization:        input.organization
		//   image:               input.repositorys
		//  }
		// }
	}

	output: #Output & {
		image:   _install.output.image
		success: _install.output.success
	}
}
