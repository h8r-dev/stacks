package github

import (
	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"github.com/h8r-dev/stacks/chain/internal/scm/github"
)

dagger.#Plan & {
	client: env: {
		APP_NAME:     string
		ORGANIZATION: string
		GITHUB_TOKEN: dagger.#Secret
	}

	actions: {
		test: {
			applicationName: client.env.APP_NAME
			accessToken:     client.env.GITHUB_TOKEN
			organization:    client.env.ORGANIZATION

			_source: core.#Source & {
				path: "code"
			}

			initHelmRepo: github.#InitRepo & {
				suffix:            "-deploy"
				sourceCodePath:    "helm"
				isHelmChart:       "true"
				"applicationName": applicationName
				"accessToken":     accessToken
				"organization":    organization
				sourceCodeDir:     _source.output
				repoVisibility:    "public"
			}

			getOrganizationMembers: github.#GetOrganizationMembers & {
				"accessToken":  accessToken
				"organization": organization
			}
		}

		testd: {
			applicationName: client.env.APP_NAME
			accessToken:     client.env.GITHUB_TOKEN
			organization:    client.env.ORGANIZATION

			deleteHelmRepo: github.#DeleteRepo & {
				suffix:            "-deploy"
				"applicationName": applicationName
				"accessToken":     accessToken
				"organization":    organization
			}
		}
	}
}
