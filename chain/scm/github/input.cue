package github

import (
	"universe.dagger.io/docker"
	"dagger.io/dagger"
)

#Input: {
	organization:        string
	personalAccessToken: dagger.#Secret
	image:               docker.#Image
	visibility:          string
}
