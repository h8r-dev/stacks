package test

import (
	"dagger.io/dagger"
	"github.com/h8r-dev/chain/supply/scaffold"
	"github.com/h8r-dev/chain/scm/github"
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
		test: github.#Instance & {
			input: github.#Input & {
				image:               _run.output.image
				organization:        client.env.ORGANIZATION
				personalAccessToken: client.env.GITHUB_TOKEN
			}
		}
	}
}
