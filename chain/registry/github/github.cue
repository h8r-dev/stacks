package github

import (
	"universe.dagger.io/bash"
	"strings"
)

#Instance: {
	input: #Input
	do:    bash.#Run & {
		env: {
			NAME:         input.chartName
			ORGANIZATION: strings.ToLower(input.organization)
			DIR_NAME:     input.name
			HELM_SET:     input.set
		}
		"input": input.image
		workdir: "/scaffold/\(input.chartName)"
		script: contents: """
				cd $DIR_NAME
				set="yq -i $HELM_SET values.yaml"
				eval $set
			"""
	}
	output: #Output & {
		image: do.output
	}
}
