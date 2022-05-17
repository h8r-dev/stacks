package helm

import (
	"universe.dagger.io/docker"
	"github.com/h8r-dev/stacks/chain/factory/basefactory"
)

#Input: {
	name:      string
	chartName: string
	image:     docker.#Image
	// Helm values set
	// Format: '.image.repository = "rep" | .image.tag = "tag"'
	set?: string | *""
	// Helm starter scaffold
	starter?:               string | *""
	domain:                 basefactory.#DefaultDomain
	gitOrganization?:       string
	appName:                string
	ingressHostPath:        string | *"/"
	rewriteIngressHostPath: bool | *false
}
