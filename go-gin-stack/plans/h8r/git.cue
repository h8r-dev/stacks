package h8r

import (
	"alpha.dagger.io/dagger"
	"alpha.dagger.io/dagger/op"
	"alpha.dagger.io/alpine"
)

// Init git repo
#InitRepo: {
    // Infra check success
    checkInfra: dagger.#Input & {string}

	// Application name, will be set as repo name
	applicationName: dagger.#Input & {string}

	// Github personal access token, and will also use to pull ghcr.io image
	accessToken: dagger.#Input & {dagger.#Secret}

	// Github organization name or username, currently only supported username
	organization: dagger.#Input & {string}

    // Source code path, for example code/go-gin
	sourceCodePath: dagger.#Input & {string}

	// TODO default repoDir path, now you can set "." with dagger dir type
	sourceCodeDir: dagger.#Artifact @dagger(input)

    // Helm chart
    isHelmChart: dagger.#Input & {string} | *"false"

    // Git URL
	gitUrl: {
		string

		#up: [
			op.#Load & {
				from: alpine.#Image & {
					package: bash:         true
					package: jq:           true
					package: git:          true
					package: curl:         true
					package: sed:          true
					package: "github-cli": true
				}
			},

			op.#Exec & {
				mount: "/run/secrets/github": secret: accessToken
				mount: "/root": from:                sourceCodeDir
				dir: "/root"
				env: {
					REPO_NAME:    applicationName
					ORGANIZATION: organization
                    SOURCECODEPATH: sourceCodePath
                    ISHELMCHART: isHelmChart
				}
				args: [
                    "/bin/bash",
                    "--noprofile",
                    "--norc",
                    "-eo",
                    "pipefail",
                    "-c",
                        #"""
                            if [ "$ISHELMCHART" == "true" ]; then
                                BACKEND_NAME=$REPO_NAME
                                FRONTEND_NAME=$REPO_NAME-front
                                REPO_NAME=$REPO_NAME-helm
                            fi
                            username=$(curl -sH "Authorization: token $(cat /run/secrets/github)" https://api.github.com/user | jq .login | sed 's/\"//g')
                            check=$(curl -sH "Authorization: token $(cat /run/secrets/github)" https://api.github.com/repos/$username/$REPO_NAME | jq .id)
                            if [ "$check" == "null" ]; then
                                echo "repo not exist"
                            else
                                echo "repo already created"
                                echo https://github.com/$username/$REPO_NAME.git > /create.json
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
                            export SSH_URL=$(cat /create.json | jq .ssh_url | sed 's/\"//g')
                            export GIT_URL=$(cat /create.json | jq .clone_url | sed 's?https://?https://'$GIT_USERNAME':'$(cat /run/secrets/github)'@?' | sed 's/\"//g')
                            echo $GIT_URL
                            cd $SOURCECODEPATH && git init && git remote add origin $GIT_URL
                            
                            echo $SSH_URL > /create.json

                            export GITHUB_TOKEN="$(cat /run/secrets/github)"
                            # add action secret
                            # gh secret set ACCESS_TOKEN < /run/secrets/github --repos $REPO_NAME
                            # push empty commit
                            curl -sH "Authorization: token $(cat /run/secrets/github)" https://api.github.com/user/emails > /user.json
                            GITHUB_EMAIL=$(cat /user.json | jq '.[0] | .email' | sed 's/\"//g')
                            curl -sH "Authorization: token $(cat /run/secrets/github)" https://api.github.com/user > /user_info.json
                            GITHUB_ID=$(cat /user_info.json | jq '.login' | sed 's/\"//g')

                            echo $GITHUB_EMAIL
                            echo $GITHUB_ID
                            git config --global user.email $GITHUB_EMAIL

                            # (replace by action) add label link image and docker, package will be public
                            # link_repo="LABEL org.opencontainers.image.source=https://github.com/$GITHUB_ID/$REPO_NAME"
                            # sed -i "8 a $link_repo"  Dockerfile
                            
                            if [ "$ISHELMCHART" == "true" ]; then
                                # edit helm chart image, yq 4.0 not working here
                                # TODO download different architecture binary
                                wget "https://github.com/mikefarah/yq/releases/download/3.4.1/yq_linux_arm64" -O /usr/bin/yq && chmod +x /usr/bin/yq
                                yq w -i /root/helm/values.yaml image.repository ghcr.io/$GITHUB_ID/$BACKEND_NAME
                                yq w -i /root/helm/values.yaml frontImage.repository ghcr.io/$GITHUB_ID/$FRONTEND_NAME
                                yq w -i /root/helm/values.yaml nocalhost.backend.dev.gitUrl git@github.com:$GITHUB_ID/$BACKEND_NAME.git
                                yq w -i /root/helm/values.yaml nocalhost.frontend.dev.gitUrl git@github.com:$GITHUB_ID/$FRONTEND_NAME.git
                                yq w -i /root/helm/Chart.yaml name $BACKEND_NAME
                            fi

                            git add .
                            git commit -m 'init repo'
                            git branch -M main
                            git push -u origin main
                            
                            if [ "$ISHELMCHART" == "true" ]; then
                                echo "ISHELMCHART:" $ISHELMCHART
                                exit 0
                            fi

                            # wait for package
                            while [[ "$(curl -sH "Authorization: token $(cat /run/secrets/github)" https://api.github.com/repos/$GITHUB_ID/$REPO_NAME/actions/runs | jq --raw-output ''.workflow_runs[0].status'')" != "completed" ]]; 
                            do
                            echo "Waiting for package..."
                            sleep 5
                            done
                        """#,
				]
				always: true
			},

			op.#Export & {
				source: "/create.json"
				format: "string"
			},
		]
	} @dagger(output)
}
