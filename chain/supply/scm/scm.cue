package scm

import (
	"github.com/h8r-dev/chain/scm/github"
)

#Instance: {
	provider: "github": github

	input: #Input

	do: {
		provider[input.provider].#Instance & {
			"input": provider[input.provider].#Input & {
				personalAccessToken: input.personalAccessToken
				organization:        input.organization
				image:               input.repositorys
				visibility:          input.visibility
				kubeconfig:          input.kubeconfig
			}
		}
	}

	output: #Output & {
		image:   do.output.image
		success: do.output.success
	}
}
