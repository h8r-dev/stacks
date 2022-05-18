package github

import (
	"universe.dagger.io/docker"
	"dagger.io/dagger"
)

#Input: {
	// Application name, for looking application path in deploy
	name: string
	// Chart name, for looking deploy path
	chartName: string
	image:     docker.#Image
	username:  string
	password:  dagger.#Secret
	tag:       string | *"main"
	appName:   string
	// set:       string | *#"""
	//  '.image.repository = "ghcr.io/\#(username)/\#(name)" | .image.tag = "\#(tag)" | .imagePullSecrets[0].name="regcred"'
	//  """#
}
