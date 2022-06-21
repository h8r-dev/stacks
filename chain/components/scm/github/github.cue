package github

import (
	"dagger.io/dagger/core"
	"strings"
	"universe.dagger.io/bash"
	"universe.dagger.io/docker"
)

#Instance: {
	input: #Input

	_file: core.#Source & {
		path: "terraform"
	}

	_copy: docker.#Copy & {
		"input":  input.image
		contents: _file.output
		dest:     "/terraform"
	}

	src: core.#Source & {
		path: "."
	}

	do: bash.#Run & {
		env: {
			GITHUB_TOKEN:        input.personalAccessToken
			GITHUB_ORGANIZATION: input.organization
			VISIBILITY:          input.visibility
			// for terraform
			TF_VAR_github_token:  input.personalAccessToken
			TF_VAR_organization:  input.organization
			TF_VAR_namespace:     "default"
			TF_VAR_secret_suffix: strings.ToLower(input.organization)
		}
		// for terraform backend
		mounts: kubeconfig: {
			dest:     "/kubeconfig"
			contents: input.kubeconfig
		}
		always:  true
		"input": _copy.output
		workdir: "/scaffold"
		script: {
			directory: src.output
			filename:  "create-github-repo.sh"
		}
	}
	output: #Output & {
		image: do.output
	}
}
