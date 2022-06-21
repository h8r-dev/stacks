package github

import (
	"dagger.io/dagger"
	"universe.dagger.io/docker"
)

#Input: {
	// Application name, for looking application path in deploy
	name: string

	// Chart name, for looking deploy path
	chartName: string

	image:       docker.#Image
	username:    string
	password:    dagger.#Secret
	tag:         string | *"main"
	appName:     string
	kubeconfig?: dagger.#Secret
}
