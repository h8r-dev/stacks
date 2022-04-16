package test

import (
	"dagger.io/dagger"
	"universe.dagger.io/bash"
	"github.com/h8r-dev/chain/supply/scaffold"
)

dagger.#Plan & {
	actions: {
		_input: scaffold.#Input & {
			provider:     "github"
			organization: "lyzhang1999"
			repository: [
				{
					name:       "docs-frontend"
					type:       "frontend"
					framework:  "next"
					visibility: "private"
					ci:         "github"
				},
				{
					name:       "docs-backend"
					type:       "backend"
					framework:  "gin"
					visibility: "private"
					ci:         "github"
				},
				{
					name:       "docs-deploy"
					type:       "deploy"
					framework:  "helm"
					visibility: "private"
					ci:         "github"
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
				},
			]
		}
		_run: scaffold.#Instance & {
			input: _input
		}
		test: bash.#Run & {
			input:  _run.output.image
			always: true
			script: contents: """
				cd /scaffold
				ls
				"""
		}
	}
}
