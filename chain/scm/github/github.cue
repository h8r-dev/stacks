package github

import (
	"universe.dagger.io/bash"
	"universe.dagger.io/docker"
	"dagger.io/dagger/core"
	"strings"
)

#Instance: {
	input: #Input

	_file: core.#Source & {
		path: "terraform"
	}

	_copy: docker.#Copy & {
		"input":  input.image
		contents: _file.output
		dest:     "/terraform"
	}

	do: bash.#Run & {
		env: {
			GITHUB_TOKEN:        input.personalAccessToken
			GITHUB_ORGANIZATION: input.organization
			VISIBILITY:          input.visibility
			// for terraform
			TF_VAR_github_token:  input.personalAccessToken
			TF_VAR_organization:  input.organization
			TF_VAR_namespace:     "default"
			TF_VAR_secret_suffix: strings.ToLower(input.organization)
		}
		// for terraform backend
		mounts: kubeconfig: {
			dest:     "/kubeconfig"
			contents: input.kubeconfig
		}
		always:  true
		"input": _copy.output
		workdir: "/scaffold"
		script: contents: """
				# //TODO save github PAT and organization may unsafe
				mkdir -p /scm/github
				printf $GITHUB_TOKEN > /scm/github/pat
				printf $GITHUB_ORGANIZATION > /scm/github/organization

				# put output info
				mkdir -p /hln
				touch /hln/output.yaml


				for file in ./*
				do
					# remove dot of ./xxx-xxx
					repoName=$(echo $file | tr -d './')
					cd /scaffold/$file

					yq -i '.scm.repos += [{"secret_suffix": "'$TF_VAR_secret_suffix$repoName'", "namespace": "'$TF_VAR_namespace'", "repo_name": "'$repoName'", "repo_visibility": "'$VISIBILITY'"}]' /hln/output.yaml

					# if .git not exist, init
					if [ ! -d .git ]; then
						# git init
						git init
						# add remote origin first
						git config remote.origin.url >&- || git remote add origin https://github.com/$GITHUB_ORGANIZATION/$repoName
					fi
					echo "init $repoName done"
					# skip push action while repo exist
					output="$(gh repo list $GITHUB_ORGANIZATION --jq '.[] | select(.name=="'$repoName'")' --json name)"
					if [[ -n $output ]]; then
						continue
					fi
					
					# Create private or public repository
					# gh repo create $GITHUB_ORGANIZATION/$repoName --$VISIBILITY -d "Heighliner stack init repo"
					# use terraform to create repositry and set PAT secret
					terraform -chdir=/terraform init -reconfigure -backend-config "secret_suffix=$TF_VAR_secret_suffix$repoName" -backend-config "namespace=$TF_VAR_namespace"
					terraform -chdir=/terraform apply -auto-approve -var "repo_name=$repoName" -var "repo_visibility=$VISIBILITY"

					# Set PAT for checkout helm chart repositry and push helm chart repositry
					# gh secret set PAT --repos $GITHUB_ORGANIZATION/$repoName < /scm/github/pat

					# wait 5 sec
					sleep 5
					# set remote url with PAT for git push
					git remote set-url origin https://$(echo $GITHUB_TOKEN)@github.com/$GITHUB_ORGANIZATION/$repoName
					git config --global user.email "heighliner@h8r.dev"

					# git commit and push
					git add .
					git commit -m "init: heighliner stack"
					git branch -M main
					git push origin main

					# set remote origin without PAT
					git remote set-url origin https://github.com/$GITHUB_ORGANIZATION/$repoName
				done
			"""
	}
	output: #Output & {
		image: do.output
	}
}
