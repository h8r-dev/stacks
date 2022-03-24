package main

import (
	"dagger.io/dagger"
)

dagger.#Plan & {
	client: env: {
		KUBECONFIG_DATA: dagger.#Secret
		APP_NAME:        string
		GITHUB_TOKEN:    dagger.#Secret
	}

	actions: {
		deleteNocalhost: #DeleteChart & {
			releasename: "nocalhost"
			kubeconfig:  client.env.KUBECONFIG_DATA
		}
		deleteRepos: #DeleteRepos & {
			appname:     client.env.APP_NAME
			githubtoken: client.env.GITHUB_TOKEN
		}
	}
}
