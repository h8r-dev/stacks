package github

import (
	"dagger.io/dagger"
	"universe.dagger.io/alpine"
	"universe.dagger.io/bash"
)

#GetOrganizationMembers: {
	accessToken:  dagger.#Secret
	organization: string

	baseImage: alpine.#Build & {
		packages: {
			bash: {}
			curl: {}
			jq: {}
		}
	}

	run: bash.#Run & {
		always: true
		input:  baseImage.output
		env: TOKEN:       accessToken
		script: contents: #"""
		username=$(curl -sH "Authorization: token ${TOKEN}" https://api.github.com/user | jq -r '.login') > /result
		if [ "$username" == \#(organization) ]; then
			# personal github name
			exit 0
		else
			# github organization name
			curl -sH "Authorization: token ${TOKEN}" https://api.github.com/orgs/\#(organization)/members | jq -r '.[].login' > /result
		fi
		"""#

		export: files: "/result": string
	}

	output:  run.export.files."/result"
	success: run.success
}
