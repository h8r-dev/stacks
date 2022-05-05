package github

import (
	"universe.dagger.io/bash"
	"strings"
)

#Instance: {
	input: #Input
	do:    bash.#Run & {
		env: {
			NAME:     input.chartName
			USERNAME: strings.ToLower(input.username)
			PASSWORD: input.password
			DIR_NAME: input.name
			//HELM_SET: input.set
			TAG: input.tag
		}
		"input": input.image
		// work dir is deploy path
		workdir: "/scaffold/\(input.chartName)"
		script: contents: """
				cd $DIR_NAME
				#set="yq -i $HELM_SET values.yaml"
				#eval $set
				yq -i '.image.repository = "ghcr.io/'$USERNAME'/'$DIR_NAME'" | .image.tag = "'$TAG'" | .imagePullSecrets[0].name="regcred"' values.yaml
				# Add image pull secret file
				kubectl create secret docker-registry regcred --docker-server="ghcr.io" --docker-username=$USERNAME --docker-password=$PASSWORD --dry-run=client -o yaml > ./templates/imagepullsecret.yaml
			"""
	}
	output: #Output & {
		image: do.output
	}
}
