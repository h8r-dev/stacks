package test

import (
	"dagger.io/dagger"
	"github.com/h8r-dev/stacks/chain/v3/component/env"
	"github.com/h8r-dev/stacks/chain/v3/internal/var"
)

dagger.#Plan & {
	client: {
		env: {
			ORGANIZATION:    string
			GITHUB_TOKEN:    dagger.#Secret
			ENV_NAME:        string
			APP_NAME:        string
			APP_DOMAIN:      string | *"h8r.site"
			NETWORK_TYPE:    string | *"default"
			REPO_VISIBILITY: string | *"private"
		}
	}
	actions: test: {
		args: {
			name:           client.env.APP_NAME
			domain:         client.env.APP_DOMAIN
			networkType:    client.env.NETWORK_TYPE
			repoVisibility: client.env.REPO_VISIBILITY
			organization:   client.env.ORGANIZATION
			githubToken:    client.env.GITHUB_TOKEN
			envName:        client.env.ENV_NAME
			frameworks: [
				{
					name: "gin"
				},
				{
					name: "next"
				},
			]
			addons: [
				{
					name: "nocalhost"
				},
				{
					name: "prometheus"
				},
			]
		}
		_var: var.#Generator & {
			input: {
				applicationName: args.name
				domain:          args.domain
				networkType:     args.networkType
				organization:    args.organization
				frameworks:      args.frameworks
				addons:          args.addons
			}
		}
		env.#Create & {
			input: {
				envName:         client.env.ENV_NAME
				appName:         client.env.APP_NAME
				scmOrganization: client.env.ORGANIZATION
				githubToken:     client.env.GITHUB_TOKEN
				vars:            _var
				domain:          args.domain
				frameworks:      args.frameworks
			}
		}
	}
}
