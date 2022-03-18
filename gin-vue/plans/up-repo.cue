package main

import (
	"dagger.io/dagger"
	"universe.dagger.io/alpine"
	"universe.dagger.io/bash"
	"universe.dagger.io/docker"
)

dagger.#Plan & {
	client: {
		filesystem: "code/": read: contents: dagger.#FS
		env: {
			GITHUB_TOKEN: dagger.#Secret
			APP_NAME:     string
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
						git: {}
					}
				},
				docker.#Copy & {
					contents: client.filesystem."code/".read.contents
					dest:     "/src"
				},
				bash.#Run & {
					env: GITHUB_TOKEN: client.env.GITHUB_TOKEN
					script: contents: #"""
						mkdir /output /github
						curl -sH "Authorization: token $GITHUB_TOKEN" https://api.github.com/user > /github/user.json
						curl -sH "Authorization: token $GITHUB_TOKEN" https://api.github.com/user/emails > /github/email.json
						"""#
				},
			]
		}
		up: initRepos: {
			backend: #GithubCreate & {
				input:   deps.output
				workdir: "/src/go-gin"
				#suffix: "-backend"
			}
			frontend: #GithubCreate & {
				input:   deps.output
				workdir: "/src/vue-front"
				#suffix: "-frontend"
			}
			helm: #GithubCreate & {
				input:   deps.output
				workdir: "/src/helm"
				#suffix: "-helm"
			}
		}
	}

	#GithubCreate: bash.#Run & {
		#appname: client.env.APP_NAME
		#suffix:  string
		#token:   client.env.GITHUB_TOKEN

		env: REPO_NAME:    "\(#appname)\(#suffix)"
		env: GITHUB_TOKEN: #token
		script: contents: #"""
			curl -XPOST -d '{"name":"'$REPO_NAME'"}' -sH "Authorization: token $GITHUB_TOKEN" https://api.github.com/user/repos > /github/repo.json
			export GITHUB_USER=$(cat /github/user.json | jq -r '.login')
			export GITHUB_EMAIL=$(cat /github/email.json | jq -r '[.[] | .email] | .[0]')
			export HTTPS_URL=https://$GITHUB_TOKEN@github.com/$GITHUB_USER/$REPO_NAME.git
			git config --global user.name $GITHUB_USER
			git config --global user.email $GITHUB_EMAIL

			git init
			git add .
			git commit -m "first commit"
			git branch -M main
			git remote add origin $HTTPS_URL
			git push -u origin main
			"""#
	}
}
