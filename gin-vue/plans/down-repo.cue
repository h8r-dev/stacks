package main

import (
	"dagger.io/dagger"
	"universe.dagger.io/alpine"
	"universe.dagger.io/bash"
	"universe.dagger.io/docker"
)

dagger.#Plan & {
	client: {
		filesystem: "output/": write: contents: actions.down.deleteGithubRepos.result.output
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
				bash.#Run & {
					workdir: "/src"
					env: HLN_APP_NAME: client.env.HLN_APP_NAME
					env: GITHUB_TOKEN: client.env.GITHUB_TOKEN
					script: contents: #"""
                        mkdir /output /github
                        curl -sH "Authorization: token $GITHUB_TOKEN" https://api.github.com/user > /github/userinfo
                        cat /github/userinfo | jq -r '.login' > /github/username
                        """#
				},
			]
		}
		down: {
			deleteGithubRepos: {
				backend: bash.#Run & {
                    always: true
					input:   deps.output
					workdir: "/src"
                    env: HLN_APP_NAME: client.env.HLN_APP_NAME
					env: GITHUB_TOKEN: client.env.GITHUB_TOKEN
					script: contents: #"""
                        export GITHUB_USER_NAME=$(cat /github/username)
                        curl -XDELETE -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/repos/$GITHUB_USER_NAME/$HLN_APP_NAME-backend > /output/deleteback
                        """#
				}
				frontend: bash.#Run & {
                    always: true
					input:   backend.output
					workdir: "/src"
                    env: HLN_APP_NAME: client.env.HLN_APP_NAME
					env: GITHUB_TOKEN: client.env.GITHUB_TOKEN
					script: contents: #"""
                        export GITHUB_USER_NAME=$(cat /github/username)
                        curl -XDELETE -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/repos/$GITHUB_USER_NAME/$HLN_APP_NAME-frontend > /output/deletefront
                        """#
				}
				helm: bash.#Run & {
                    always: true
					input:   frontend.output
					workdir: "/src"
                    env: HLN_APP_NAME: client.env.HLN_APP_NAME
					env: GITHUB_TOKEN: client.env.GITHUB_TOKEN
					script: contents: #"""
                        export GITHUB_USER_NAME=$(cat /github/username)
                        curl -XDELETE -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/repos/$GITHUB_USER_NAME/$HLN_APP_NAME-helm > /output/deletehelm
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