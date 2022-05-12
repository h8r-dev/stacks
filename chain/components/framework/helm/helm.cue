package helm

import (
	"universe.dagger.io/bash"
)

#Instance: {
	defaultStarter: {
		url:      "https://github.com/h8r-dev/helm-starter.git"
		repoName: "helm-starter"
	}
	input: #Input
	do:    bash.#Run & {
		env: {
			NAME: input.chartName
			if input.set != _|_ {
				HELM_SET: input.set
			}
			DIR_NAME:          input.name
			STARTER_REPO_URL:  defaultStarter.url
			STARTER_REPO_NAME: defaultStarter.repoName
			if input.starter != _|_ {
				STARTER: input.starter
			}
			if input.gitOrganization != _|_ {
				GIT_ORGANIZATION: input.gitOrganization
			}
		}
		"input": input.image
		// helm deploy dir path
		workdir: "/scaffold/\(input.name)"
		script: contents: """
			printf '## :warning: DO NOT MAKE THIS REPOSITORY PUBLIC' > README.md
			if [ ! -z "$STARTER" ]; then
				git clone "$STARTER_REPO_URL" $HOME/.local/share/helm/starters/${STARTER_REPO_NAME}
				helm create $NAME -p $STARTER
			else
				helm create $NAME
			fi

			# nocalhost dev config
			if [ -f "${NAME}/conf/nocalhost.yaml" ]; then
			echo "set nocalhost dev config"
			mkdir .nocalhost
			cat << EOF > .nocalhost/config.yaml
			configProperties:
			  version: v2
			application:
			  helmValues:
			    - key: nocalhost.enabled
			      value: true
			EOF
			# FixMe: hardcoded
				git_url="https://github.com/${GIT_ORGANIZATION}/${NAME}"
				yq -i '.nocalhost.gitUrl = "'${git_url}'"' "${NAME}/values.yaml"
			fi

			cd $NAME
			if [ ! -z "$HELM_SET" ]; then
				set="yq -i $HELM_SET values.yaml"
				eval $set
			fi
			# set domain
			domain=$NAME.\(input.domain.application.domain)
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
