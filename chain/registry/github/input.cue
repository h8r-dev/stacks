package github

import (
	"universe.dagger.io/docker"
)

#Input: {
	// Application name, for looking application path in deploy
	name: string
	// Chart name, for looking deploy path
	chartName:    string
	image:        docker.#Image
	organization: string
	tag:          string | *"main"
	set:          string | *#"""
		'.image.repository = "ghcr.io/\#(organization)/\#(name)" | .image.tag = "\#(tag)"'
		"""#
}
