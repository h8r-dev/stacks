package nocalhost

import (
	"dagger.io/dagger"
	"universe.dagger.io/docker"
)

#Input: {
	image:              docker.#Image
	url:                string | *"nocalhost-web.nocalhost"
	githubAccessToken:  dagger.#Secret
	githubOrganization: string
	kubeconfig:         string | dagger.#Secret
	appName:            string
	// appGitURL:          string
	// waitFor: bool
}
