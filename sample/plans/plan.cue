package main

import (
	"dagger.io/dagger"
	// "universe.dagger.io/alpine"
	// "universe.dagger.io/bash"
	// "universe.dagger.io/docker"
)

dagger.#Plan & {
	client: {
		commands: kubeconfig: {
			name: "cat"
			args: ["\(env.KUBECONFIG)"]
			stdout: dagger.#Secret
		}
		env: {
			KUBECONFIG:   string
			APP_NAME:     string
			ORGANIZATION: string
			GITHUB_TOKEN: dagger.#Secret
		}
		filesystem: code: read: contents:    dagger.#FS
		filesystem: output: write: contents: actions.up.run.output
	}

	actions: {
		up: initRepos: {
			applicationName: client.env.APP_NAME
			accessToken:     client.env.GITHUB_TOKEN
			organization:    client.env.ORGANIZATION
			sourceCodeDir:   client.filesystem.code.read.contents

			initRepo: #InitRepo & {
				sourceCodePath:    "go-gin"
				suffix:            ""
				"applicationName": applicationName
				"accessToken":     accessToken
				"organization":    organization
				"sourceCodeDir":   sourceCodeDir
			}

			initFrontendRepo: #InitRepo & {
				suffix:            "-front"
				sourceCodePath:    "vue-front"
				"applicationName": applicationName
				"accessToken":     accessToken
				"organization":    organization
				"sourceCodeDir":   sourceCodeDir
			}

			initHelmRepo: #InitRepo & {
				suffix:            "-deploy"
				sourceCodePath:    "helm"
				isHelmChart:       "true"
				"applicationName": applicationName
				"accessToken":     accessToken
				"organization":    organization
				"sourceCodeDir":   sourceCodeDir
			}
		}
		down: deleteRepos: {
			applicationName: client.env.APP_NAME
			accessToken:     client.env.GITHUB_TOKEN
			organization:    client.env.ORGANIZATION

			deleteRepo: #DeleteRepo & {
				suffix:            ""
				"applicationName": applicationName
				"accessToken":     accessToken
				"organization":    organization
			}

			deleteFrontendRepo: #DeleteRepo & {
				suffix:            "-front"
				"applicationName": applicationName
				"accessToken":     accessToken
				"organization":    organization
			}

			deleteHelmRepo: #DeleteRepo & {
				suffix:            "-deploy"
				"applicationName": applicationName
				"accessToken":     accessToken
				"organization":    organization
			}
		}
	}
}
