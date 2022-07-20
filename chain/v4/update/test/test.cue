package test

import (
	"dagger.io/dagger"
	"github.com/h8r-dev/stacks/chain/v4/update"
)

dagger.#Plan & {
	client: env: GITHUB_TOKEN: dagger.#Secret
	actions: test: {
		args: internal: githubToken: client.env.GITHUB_TOKEN
		do: update.#Run & {
			"args": args
		}
	}
}
