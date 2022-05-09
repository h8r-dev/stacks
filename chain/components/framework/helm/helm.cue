package helm

import (
	"universe.dagger.io/bash"
	//"universe.dagger.io/docker"
	//"dagger.io/dagger/core"
	"github.com/h8r-dev/stacks/chain/factory/basefactory"
)

#Instance: {
	starters: "spring-boot": {
		url:         "https://github.com/h8r-dev/helm-starter-spring.git"
		starterName: "helm-starter-spring"
		name:        "spring-boot"
	}
	input: #Input
	do:    bash.#Run & {
		env: {
			NAME: input.chartName
			if input.set != _|_ {
				HELM_SET: input.set
			}
			DIR_NAME: input.name
			if input.starter != _|_ && starters[input.starter] != _|_ {
				STARTER:      starters[input.starter].name
				STARTER_URL:  starters[input.starter].url
				STARTER_NAME: starters[input.starter].starterName
			}
		}
		"input": input.image
		// helm deploy dir path
		workdir: "/scaffold/\(input.name)"
		script: contents: """
				printf '## :warning: DO NOT MAKE THIS REPOSITORY PUBLIC' > README.md
				if [ ! -z "$STARTER" ]; then
					git clone "$STARTER_URL" $HOME/.local/share/helm/starters/${STARTER_NAME}
					helm create $NAME -p $STARTER_NAME/$STARTER
				else
					helm create $NAME
				fi
				cd $NAME
				if [ ! -z "$HELM_SET" ]; then
					set="yq -i $HELM_SET values.yaml"
					eval $set
				fi
				# set domain
				domain=$NAME\(basefactory.#DefaultDomain.application.domain)
				# for output
				mkdir -p /hln
				touch /hln/output.yaml
				yq -i '.services += [{"name": "'$NAME'", "url": "'$domain'"}]' /hln/output.yaml
				# TODO RUNNING ROOT USERS IS UNSAFE
				yq -i '.ingress.enabled = true | .ingress.className = "nginx" | .ingress.hosts[0].host="'$domain'" | .securityContext = {"runAsUser": 0}' values.yaml
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
