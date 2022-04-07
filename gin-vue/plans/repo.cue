package main

import (
	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"universe.dagger.io/alpine"
	"universe.dagger.io/bash"
	"universe.dagger.io/docker"
)

#DeleteRepo: {
	// Application name, will be set as repo name
	applicationName: string

	// Suffix
	suffix: *"" | string

	accessToken: dagger.#Secret

	organization: string

	base: alpine.#Build & {
		packages: {
			bash: {}
			curl: {}
		}
	}

	run: bash.#Run & {
		input:  base.output
		always: true
		env: GITHUB_TOKEN: accessToken
		script: contents:  #"""
		curl -H "Authorization: token $GITHUB_TOKEN" -XDELETE  https://api.github.com/repos/\#(organization)/\#(applicationName)\#(suffix)
		"""#
	}
}

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
			HELM_SUFFIX='-deploy'
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
			    printf https://github.com/$username/$REPO_NAME.git > /create.json
			    if [ "$username" != "$ORGANIZATION" ]; then
			        printf https://github.com/$ORGANIZATION/$REPO_NAME.git > /create.json
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

			printf $SSH_URL > /create.json

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
			    yq3 w -i /root/helm/values.yaml ingress.hosts[0].path[0].serviceName $BACKEND_NAME-front
			    yq3 w -i /root/helm/values.yaml ingress.hosts[0].path[1].serviceName $BACKEND_NAME

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
			    printf $HELM_GIT_URL > /create.json
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

	readFile: core.#ReadFile & {
		input: run.output.rootfs
		path:  "/create.json"
	}

	url: readFile.contents
}
