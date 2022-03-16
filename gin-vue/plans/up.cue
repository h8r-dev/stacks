package main

import (
	"dagger.io/dagger"
	"universe.dagger.io/alpine"
	"universe.dagger.io/bash"
	"universe.dagger.io/docker"
)

dagger.#Plan & {
	client: {
		filesystem: {
			"code/": read: {
				contents: dagger.#FS
				exclude: [
					"go-gin/README.md",
					"vue-front/README.md",
				]
			}
			"output/": write: contents: actions.up.createGithubRepos.result.output
		}
		env: {
			GITHUB_TOKEN: dagger.#Secret
			HLN_APP_NAME: string
		}
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
				docker.#Copy & {
					contents: client.filesystem."code/".read.contents
					dest:     "/src"
				},
				bash.#Run & {
					workdir: "/src"
					env: HLN_APP_NAME: client.env.HLN_APP_NAME
					env: GITHUB_TOKEN: client.env.GITHUB_TOKEN
					script: contents: #"""
						mkdir /output /github
						"""#
				},
			]
		}
		up: {
			createGithubRepos: {
				backend: bash.#Run & {
					input:   deps.output
					workdir: "/src"
					env: HLN_APP_NAME: client.env.HLN_APP_NAME
					env: GITHUB_TOKEN: client.env.GITHUB_TOKEN
					script: contents: #"""
						curl -XPOST -d '{"name":"'$HLN_APP_NAME-backend'"}' -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user/repos >> /output/createback
						"""#
				}
				frontend: bash.#Run & {
					input:   backend.output
					workdir: "/src"
					env: HLN_APP_NAME: client.env.HLN_APP_NAME
					env: GITHUB_TOKEN: client.env.GITHUB_TOKEN
					script: contents: #"""
						curl -XPOST -d '{"name":"'$HLN_APP_NAME-frontend'"}' -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user/repos >> /output/createfront
						"""#
				}
				helm: bash.#Run & {
					input:   frontend.output
					workdir: "/src"
					env: HLN_APP_NAME: client.env.HLN_APP_NAME
					env: GITHUB_TOKEN: client.env.GITHUB_TOKEN
					script: contents: #"""
						curl -XPOST -d '{"name":"'$HLN_APP_NAME-helm'"}' -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user/repos >> /output/createhelm
						"""#
				}
				result: dagger.#Subdir & {
					input: helm.output.rootfs
					path:  "/output"
				}
			}
		}
	}
}
