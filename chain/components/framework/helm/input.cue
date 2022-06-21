package helm

import (
	"github.com/h8r-dev/stacks/chain/factory/basefactory"
	"universe.dagger.io/docker"
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
	mergeAllCharts:         bool | *false
	repositoryType:         string | *"frontend" | "backend" | "deploy"
}
