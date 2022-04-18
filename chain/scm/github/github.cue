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
		}
		always:  true
		"input": input.image
		workdir: "/scaffold"
		script: contents: """
				for file in ./*
				do
					# remove dot of ./xxx-xxx
					repoName=$(echo $file | tr -d './')
					output="$(gh repo list $GITHUB_ORGANIZATION --jq '.[] | select(.name=="'$repoName'")' --json name)"
					if [[ -n $output ]]; then
						continue
					fi
					cd $file
					git init
					
					gh repo create $GITHUB_ORGANIZATION/$repoName --source . --public -d "Heighliner stack init repo"
					
					# set remote url with PAT
					git remote set-url origin https://$(echo $GITHUB_TOKEN)@github.com/$GITHUB_ORGANIZATION/$repoName
					git config --global user.email "heighliner@h8r.dev"
					git add .
					git commit -m "init: heighliner stack"
					git branch -M main
					git push origin main
					cd ..
				done
			"""
	}
	output: #Output & {
		image: do.output
	}
}
