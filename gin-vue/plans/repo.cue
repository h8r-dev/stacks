package main

import (
	"dagger.io/dagger"
	"universe.dagger.io/alpine"
	"universe.dagger.io/bash"
	"universe.dagger.io/docker"
)

#InitRepo: {

	// Application name, will be set as repo name
	applicationName: string

	// Suffix
	suffix: *"" | string

	// Github personal access token, and will also use to pull ghcr.io image
	accessToken: dagger.#Secret

	// Github organization name or username
	organization: string

	// Source code path, for example code/go-gin
	sourceCodePath: string

	sourceCodeDir: dagger.#FS

	// Helm chart
	isHelmChart: string | *"false"

	base: docker.#Build & {
		steps: [
			alpine.#Build & {
				packages: {
					bash: {}
					curl: {}
					wget: {}
					"github-cli": {}
					git: {}
					jq: {}
				}
			},
			docker.#Copy & {
				contents: sourceCodeDir
				dest:     "/root"
			},
		]
	}

	run: bash.#Run & {
		input: base.output
		export: files: "/create.json": _
		workdir: "/root"
		always:  true
		env: {
			GITHUB_TOKEN:     accessToken
			APPLICATION_NAME: applicationName
			SUFFIX:           suffix
			ORGANIZATION:     organization
			SOURCECODEPATH:   sourceCodePath
			ISHELMCHART:      isHelmChart
		}
		script: contents: #"""
			mkdir -p /run/secrets
			echo $GITHUB_TOKEN > /run/secrets/github
			HELM_SUFFIX='-helm'
			FRONT_SUFFIX='-front'
			REPO_NAME=$APPLICATION_NAME$SUFFIX
			if [ "$ISHELMCHART" == "true" ]; then
			    BACKEND_NAME=$APPLICATION_NAME
			    FRONTEND_NAME=$APPLICATION_NAME$FRONT_SUFFIX
			fi
			username=$(curl -sH "Authorization: token $(cat /run/secrets/github)" https://api.github.com/user | jq .login | sed 's/\"//g')
			if [ "$username" == "$ORGANIZATION" ]; then
			    check=$(curl -sH "Authorization: token $(cat /run/secrets/github)" https://api.github.com/repos/$username/$REPO_NAME | jq .id)
			else
			    check=$(curl -sH "Authorization: token $(cat /run/secrets/github)" https://api.github.com/orgs/$ORGANIZATION/repos?direction=desc | jq '.[] | select(.name=="'$REPO_NAME'") | .id')
			fi
			if [ "$check" == "null" ] || [ "$check" == "" ]; then
			    echo "repo not exist"
			else
			    echo "repo already created"
			    echo https://github.com/$username/$REPO_NAME.git > /create.json
			    if [ "$username" != "$ORGANIZATION" ]; then
			        echo https://github.com/$ORGANIZATION/$REPO_NAME.git > /create.json
			    fi
			    exit 0
			fi
			if [ "$username" == "$ORGANIZATION" ]; then
			    echo "create personal repo"
			    curl -sH "Authorization: token $(cat /run/secrets/github)" --data '{"name":"'$REPO_NAME'"}' https://api.github.com/user/repos > /create.json
			else
			    echo "create organization repo"
			    curl -sH "Authorization: token $(cat /run/secrets/github)" --data '{"name":"'$REPO_NAME'"}' https://api.github.com/orgs/$ORGANIZATION/repos > /create.json
			fi
			export GIT_USERNAME=$(cat /create.json | jq .clone_url | cut -d/ -f4)
			export HELM_GIT_URL=$(cat /create.json | jq --raw-output .clone_url)
			export SSH_URL=$(cat /create.json | jq .ssh_url | sed 's/\"//g')
			export GIT_URL=$(cat /create.json | jq .clone_url | sed 's?https://?https://'$GIT_USERNAME':'$(cat /run/secrets/github)'@?' | sed 's/\"//g')
			echo $GIT_URL
			cd $SOURCECODEPATH && git init && git remote add origin $GIT_URL

			echo $SSH_URL > /create.json

			export GITHUB_TOKEN="$(cat /run/secrets/github)"

			# push empty commit
			curl -sH "Authorization: token $(cat /run/secrets/github)" https://api.github.com/user/emails > /user.json
			GITHUB_EMAIL=$(cat /user.json | jq '.[0] | .email' | sed 's/\"//g')
			curl -sH "Authorization: token $(cat /run/secrets/github)" https://api.github.com/user > /user_info.json
			GITHUB_ID=$(cat /user_info.json | jq '.login' | sed 's/\"//g')

			# organization id
			if [ "$username" != "$ORGANIZATION" ]; then
			    GITHUB_ID=$ORGANIZATION
			fi

			# add action secret for user repo
			gh secret set PAT < /run/secrets/github --repos $GITHUB_ID/$REPO_NAME

			git config --global user.email $GITHUB_EMAIL

			# (replace by action) add label link image and docker, package will be public
			# link_repo="LABEL org.opencontainers.image.source=https://github.com/$GITHUB_ID/$REPO_NAME"
			# sed -i "8 a $link_repo"  Dockerfile

			# update github action env

			wget -q https://github.com/mikefarah/yq/releases/download/3.4.1/yq_linux_amd64 -O /usr/local/bin/yq3 && chmod +x /usr/local/bin/yq3

			if [ "$ISHELMCHART" != "true" ]; then
			    yq3 w -i ./.github/workflows/docker-publish.yml env.ORG $GITHUB_ID
			    yq3 w -i ./.github/workflows/docker-publish.yml env.HELM_REPO $APPLICATION_NAME$HELM_SUFFIX
			fi

			if [ "$ISHELMCHART" == "true" ]; then
			    # edit helm chart image, yq 4.0 not working here
			    # TODO download different architecture binary
			    yq3 w -i /root/helm/values.yaml image.repository ghcr.io/$GITHUB_ID/$BACKEND_NAME
			    yq3 w -i /root/helm/values.yaml frontImage.repository ghcr.io/$GITHUB_ID/$FRONTEND_NAME
			    yq3 w -i /root/helm/values.yaml nocalhost.backend.dev.gitUrl git@github.com:$GITHUB_ID/$BACKEND_NAME.git
			    yq3 w -i /root/helm/values.yaml nocalhost.frontend.dev.gitUrl git@github.com:$GITHUB_ID/$FRONTEND_NAME.git
			    yq3 w -i /root/helm/Chart.yaml name $BACKEND_NAME
			fi

			# wait github repo
			sleep 10
			git add .
			git commit -m 'init repo' --quiet
			git branch -M main
			git push -u origin main

			if [ "$ISHELMCHART" == "true" ]; then
			    sleep 10
			    echo $HELM_GIT_URL > /create.json
			    echo "ISHELMCHART:" $ISHELMCHART
			    exit 0
			fi

			# wait for package
			echo $GITHUB_ID
			echo $ORGANIZATION

			while [[ "$(curl -sH "Authorization: token $(cat /run/secrets/github)" https://api.github.com/repos/$GITHUB_ID/$REPO_NAME/actions/runs | jq --raw-output ''.workflow_runs[0].status'')" != "completed" ]]; 
			do
			echo "Waiting for package..."
			sleep 5
			done
			"""#
	}
}

#DeleteRepo: {
	reponame:     string
	organization: string
	githubtoken:  dagger.#Secret

	run: docker.#Build & {
		steps: [
			alpine.#Build & {
				packages: {
					bash: {}
					curl: {}
					jq: {}
				}
			},
			bash.#Run & {
				always: true
				env: {
					USER_NAME:    organization
					GITHUB_TOKEN: githubtoken
					REPO_NAME:    reponame
				}
				script: contents: #"""
					curl -XDELETE -sH "Authorization: token $GITHUB_TOKEN" https://api.github.com/repos/$USER_NAME/$REPO_NAME > output.txt
					"""#
			},
		]
	}
}

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