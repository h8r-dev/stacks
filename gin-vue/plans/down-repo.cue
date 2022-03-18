package main

import (
	"dagger.io/dagger"
	"universe.dagger.io/alpine"
	"universe.dagger.io/bash"
	"universe.dagger.io/docker"
)

dagger.#Plan & {
	client: env: {
		GITHUB_TOKEN: dagger.#Secret
		APP_NAME:     string
	}

	actions: {
		deps: docker.#Build & {
			steps: [
				alpine.#Build & {
					packages: {
						bash: {}
						curl: {}
						jq: {}
					}
				},
				bash.#Run & {
					env: GITHUB_TOKEN: client.env.GITHUB_TOKEN
					script: contents: #"""
						mkdir /output /github
						curl -sH "Authorization: token $GITHUB_TOKEN" https://api.github.com/user > /github/userinfo
						cat /github/userinfo | jq -r '.login' > /github/username
						"""#
				},
			]
		}
		down: deleteGithubRepos: {
			backend: #GithubDelete & {
				input:   deps.output
				#suffix: "backend"
			}
			frontend: #GithubDelete & {
				input:   deps.output
				#suffix: "frontend"
			}
			helm: #GithubDelete & {
				input:   deps.output
				#suffix: "helm"
			}
		}
	}

	#GithubDelete: bash.#Run & {
		#appname: client.env.APP_NAME
		#suffix:  string
		#token:   client.env.GITHUB_TOKEN

		always: true
		env: REPO_NAME:    "\(#appname)-\(#suffix)"
		env: GITHUB_TOKEN: #token
		script: contents: #"""
			export USER_NAME=$(cat /github/username)
			curl -XDELETE -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/repos/$USER_NAME/$REPO_NAME
			"""#
	}
}
