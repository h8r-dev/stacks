package main

import (
	"dagger.io/dagger"
	"universe.dagger.io/alpine"
	"universe.dagger.io/bash"
	"universe.dagger.io/docker"
)

#CreateRepos: {
	appname:        string
	sourcecode:     dagger.#FS
	githubtoken:    dagger.#Secret
	backendsuffix:  string | *"-backend"
	frontendsuffix: string | *"-frontend"
	deploysuffix:   string | *"-deploy"

	fetchinfo: #FetchGithubInfo & {
		"githubtoken": githubtoken
	}
	backendcode: dagger.#Subdir & {
		input: sourcecode
		path:  "/go-gin"
	}
	backend: #CreateGithubRepo & {
		sourcecode:    backendcode.output
		reponame:      "\(appname)\(backendsuffix)"
		githubinfo:    fetchinfo.output
		"githubtoken": githubtoken
	}
	frontendcode: dagger.#Subdir & {
		input: sourcecode
		path:  "/vue-front"
	}
	frontend: #CreateGithubRepo & {
		sourcecode:    frontendcode.output
		reponame:      "\(appname)\(frontendsuffix)"
		githubinfo:    fetchinfo.output
		"githubtoken": githubtoken
	}
	deploycode: dagger.#Subdir & {
		input: sourcecode
		path:  "/helm"
	}
	deploy: #CreateGithubRepo & {
		sourcecode:    deploycode.output
		reponame:      "\(appname)\(deploysuffix)"
		githubinfo:    fetchinfo.output
		"githubtoken": githubtoken
	}
}

#DeleteRepos: {
	appname:        string
	githubtoken:    dagger.#Secret
	backendsuffix:  string | *"-backend"
	frontendsuffix: string | *"-frontend"
	deploysuffix:   string | *"-deploy"

	fetchinfo: #FetchGithubInfo & {
		"githubtoken": githubtoken
	}
	backend: #DeleteGithubRepo & {
		reponame:      "\(appname)\(backendsuffix)"
		githubinfo:    fetchinfo.output
		"githubtoken": githubtoken
	}
	frontend: #DeleteGithubRepo & {
		reponame:      "\(appname)\(frontendsuffix)"
		githubinfo:    fetchinfo.output
		"githubtoken": githubtoken
	}
	deploy: #DeleteGithubRepo & {
		reponame:      "\(appname)\(deploysuffix)"
		githubinfo:    fetchinfo.output
		"githubtoken": githubtoken
	}
}

#FetchGithubInfo: {
	githubtoken: dagger.#Secret

	output: dagger.#FS

	run: docker.#Build & {
		steps: [
			alpine.#Build & {
				packages: {
					bash: {}
					curl: {}
				}
			},
			bash.#Run & {
				env: GITHUB_TOKEN: githubtoken
				script: contents: #"""
					mkdir /github
					curl -sH "Authorization: token $GITHUB_TOKEN" https://api.github.com/user > /github/user.json
					curl -sH "Authorization: token $GITHUB_TOKEN" https://api.github.com/user/emails > /github/email.json
					"""#
			},
		]
	}
	export: dagger.#Subdir & {
		input: run.output.rootfs
		path:  "/github"
	}
	output: export.output
}

#CreateGithubRepo: {
	sourcecode:  dagger.#FS
	reponame:    string
	githubinfo:  dagger.#FS
	githubtoken: dagger.#Secret

	run: docker.#Build & {
		steps: [
			alpine.#Build & {
				packages: {
					bash: {}
					curl: {}
					git: {}
					jq: {}
				}
			},
			docker.#Copy & {
				contents: sourcecode
				dest:     "/src"
			},
			docker.#Copy & {
				contents: githubinfo
				dest:     "/github"
			},
			bash.#Run & {
				workdir: "/src"
				env: {
					REPO_NAME:    reponame
					GITHUB_TOKEN: githubtoken
				}
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
			},
		]
	}
}

#DeleteGithubRepo: {
	reponame:    string
	githubinfo:  dagger.#FS
	githubtoken: dagger.#Secret

	run: docker.#Build & {
		steps: [
			alpine.#Build & {
				packages: {
					bash: {}
					curl: {}
					jq: {}
				}
			},
			docker.#Copy & {
				contents: githubinfo
				dest:     "/github"
			},
			bash.#Run & {
				always: true
				env: {
					GITHUB_TOKEN: githubtoken
					REPO_NAME:    reponame
				}
				script: contents: #"""
					export USER_NAME=$(cat /github/user.json | jq -r '.login')
					curl -XDELETE -sH "Authorization: token $GITHUB_TOKEN" https://api.github.com/repos/$USER_NAME/$REPO_NAME > output.txt
					"""#
			},
		]
	}
}
