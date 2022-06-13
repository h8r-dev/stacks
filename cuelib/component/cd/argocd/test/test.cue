package test

import (
	"dagger.io/dagger"
	"github.com/h8r-dev/stacks/cuelib/component/cd/argocd"
)

dagger.#Plan & {
	client: {
		env: {
			ORGANIZATION: string
			GITHUB_TOKEN: dagger.#Secret
			APP_NAME:     string
			REPO_URL:     string
			PASSWORD:     dagger.#Secret
		}
	}

	actions: {
		test: argocd.#CreateApp & {
			input: {
				name:               client.env.APP_NAME
				repositoryPassword: client.env.GITHUB_TOKEN
				repositoryURL:      client.env.REPO_URL
				appPath:            "\(name)"
				password:           client.env.PASSWORD
			}
		}
	}
}
