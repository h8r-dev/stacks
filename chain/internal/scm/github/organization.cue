package github

import (
	"dagger.io/dagger"
	"github.com/h8r-dev/stacks/chain/internal/utils/base"
	"universe.dagger.io/bash"
)

#GetOrganizationMembers: {
	accessToken:  dagger.#Secret
	organization: string

	baseImage: base.#Image

	run: bash.#Run & {
		always: true
		input:  baseImage.output
		env: TOKEN:       accessToken
		script: contents: #"""
		username=$(curl --retry 5 --retry-delay 2 -sH  "Authorization: token ${TOKEN}" https://api.github.com/user | jq -r '.login') > /result
		if [ "$username" == \#(organization) ]; then
			# personal github name
			printf "$username" > /result
			exit 0
		else
			# github organization name
			curl --retry 5 --retry-delay 2 -sH "Authorization: token ${TOKEN}" https://api.github.com/orgs/\#(organization)/members | jq -r '.[].login' > /result
		fi
		"""#

		export: files: "/result": string
	}

	output:  run.export.files."/result"
	success: run.success
}
