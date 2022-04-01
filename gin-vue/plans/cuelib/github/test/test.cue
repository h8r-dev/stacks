package random

import (
	"dagger.io/dagger"
	"universe.dagger.io/alpine"
	"universe.dagger.io/bash"
	"github.com/h8r-dev/gin-vue/plans/cuelib/github"
)

dagger.#Plan & {
	client: env: {
		ORGANIZATION: string
		GITHUB_TOKEN: dagger.#Secret
	}
	actions: {

		baseImage: alpine.#Build & {
			packages: bash: {}
		}

		githubAccessToken:  client.env.GITHUB_TOKEN
		githubOrganization: client.env.ORGANIZATION

		githubOrganizationMembers: github.#GetOrganizationMembers & {
			accessToken:  githubAccessToken
			organization: githubOrganization
		}

		test: bash.#Run & {
			input:  baseImage.output
			always: true
			script: contents: #"""
				printf 'github organization members: \#(githubOrganizationMembers.output)'
				"""#
		}
	}
}
