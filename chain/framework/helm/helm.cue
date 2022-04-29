package helm

import (
	"universe.dagger.io/bash"
	//"universe.dagger.io/docker"
	//"dagger.io/dagger/core"
	"github.com/h8r-dev/chain/supply/base"
)

#Instance: {
	input: #Input
	do:    bash.#Run & {
		env: {
			NAME: input.chartName
			if input.set != _|_ {
				HELM_SET: input.set
			}
			DIR_NAME: input.name
		}
		"input": input.image
		// helm deploy dir path
		workdir: "/scaffold/\(input.name)"
		script: contents: """
				printf '## :warning: DO NOT MAKE THIS REPOSITORY PUBLIC' > README.md
				helm create $NAME
				cd $NAME
				if [ ! -z "$HELM_SET" ]; then
					set="yq -i $HELM_SET values.yaml"
					eval $set
				fi
				# set domain
				domain=$NAME\(base.#DefaultDomain.application.domain)
				# TODO RUNNING ROOT USERS IS UNSAFE
				yq -i '.ingress.enabled = true | .ingress.hosts[0].host="'$domain'" | .securityContext = {"runAsUser": 0}' values.yaml
				mkdir -p /h8r
				printf $DIR_NAME > /h8r/application
			"""
	}
	// _outputHelm: core.#Subdir & {
	//  "input": _build.output.rootfs
	//  path:    "/tmp/\(input.chartName)"
	// }
	// do: docker.#Copy & {
	//  "input":  input.image
	//  contents: _outputHelm.output
	//  dest:     "/scaffold/\(input.name)/\(input.chartName)"
	// }
	output: #Output & {
		image: do.output
	}
}
