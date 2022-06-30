package organization

import (
	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"universe.dagger.io/bash"
	"github.com/h8r-dev/stacks/chain/internal/utils/base"
)

#Github: {
	github_token: dagger.#Secret

	github_organization: string

	_baseImage: base.#Image

	run: bash.#Run & {
		input: _baseImage.output
		env: {
			GITHUB_TOKEN:        github_token
			GITHUB_ORGANIZATION: github_organization
		}
		// if no organization provided, fetch user github login username from github api
		// and set username as organization
		script: contents: """
			  if [ -z $GITHUB_ORGANIZATION ]; then
			    printf $(gh api user --jq '.login') > /result
			  else
			    printf $GITHUB_ORGANIZATION > /result
			  fi
			"""
	}

	value: core.#ReadFile & {
		input: run.output.rootfs
		path:  "/result"
	}
}
