package test

import (
	"dagger.io/dagger"
	"github.com/h8r-dev/chain/supply/scaffold"
	"github.com/h8r-dev/chain/supply/scm"
)

dagger.#Plan & {
	client: env: {
		ORGANIZATION: string
		GITHUB_TOKEN: dagger.#Secret
	}
	actions: {
		_input: scaffold.#Input & {
			scm:          "github"
			organization: "lyzhang1999"
			repository: [
				{
					name:       "cart1-frontend"
					type:       "frontend"
					framework:  "next"
					visibility: "private"
					ci:         "github"
				},
				{
					name:       "cart1-backend"
					type:       "backend"
					framework:  "gin"
					visibility: "private"
					ci:         "github"
				},
				{
					name:       "cart1-deploy"
					type:       "deploy"
					framework:  "helm"
					visibility: "private"
					ci:         "github"
				},
			]
			addons: [
				{
					name: "prometheus"
				},
				{
					name: "loki"
				},
				{
					name: "nocalhost"
				},
			]
		}
		_run: scaffold.#Instance & {
			input: _input
		}

		_scmInput: scm.#Input & {
			provider:            "github"
			personalAccessToken: client.env.GITHUB_TOKEN
			organization:        client.env.ORGANIZATION
			repositorys:         _run.output.image
		}

		test: scm.#Instance & {
			input: _scmInput
		}
	}
}
