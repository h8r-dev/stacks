package github

import (
	"universe.dagger.io/docker"
)

#Input: {
	name:         string // Repo name
	image:        docker.#Image
	organization: string | *""
	deployRepo:   string | *""
	appName:      string | *""
}
