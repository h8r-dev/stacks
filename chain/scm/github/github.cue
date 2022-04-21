package github

import (
	"universe.dagger.io/bash"
)

#Instance: {
	input: #Input
	do:    bash.#Run & {
		env: {
			GITHUB_TOKEN:        input.personalAccessToken
			GITHUB_ORGANIZATION: input.organization
			VISIBILITY:          input.visibility
		}
		always:  true
		"input": input.image
		workdir: "/scaffold"
		script: contents: """
				# //TODO save github PAT and organization may unsafe
				mkdir -p /scm/github
				printf $GITHUB_TOKEN > /scm/github/pat
				printf $GITHUB_ORGANIZATION > /scm/github/organization
				for file in ./*
				do
					# remove dot of ./xxx-xxx
					repoName=$(echo $file | tr -d './')
					cd /scaffold/$file

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
					gh repo create $GITHUB_ORGANIZATION/$repoName --$VISIBILITY -d "Heighliner stack init repo"
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
