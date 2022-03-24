package main

import (
	"dagger.io/dagger"
)

dagger.#Plan & {
	client: env: {
		APP_NAME:     string
		ORGANIZATION: string
		GITHUB_TOKEN: dagger.#Secret
	}

	actions: {
		deleteNocalhost: #DeleteChart & {
			releasename: "nocalhost"
			kubeconfig:  client.env.KUBECONFIG_DATA
		}
		deleteRepos: {
			applicationName: client.env.APP_NAME
			accessToken:     client.env.GITHUB_TOKEN
			organization:    client.env.ORGANIZATION

			DeleteRepo: #DeleteRepo & {
				reponame:       "\(applicationName)"
				githubtoken:    accessToken
				"organization": organization
			}
			DeleteFrontendRepo: #DeleteRepo & {
				reponame:       "\(applicationName)-front"
				githubtoken:    accessToken
				"organization": organization
			}
			DeleteHelmRepo: #DeleteRepo & {
				reponame:       "\(applicationName)-deploy"
				githubtoken:    accessToken
				"organization": organization
			}
		}
	}
}
