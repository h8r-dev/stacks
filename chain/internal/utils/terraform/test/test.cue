package terraform

import (
	"dagger.io/dagger"
	"github.com/h8r-dev/stacks/chain/internal/utils/terraform"
	"universe.dagger.io/bash"
)

dagger.#Plan & {
	client: {
		env: {
			TF_VAR_REPO_NAME:       string
			TF_VAR_REPO_VISIBILITY: string
			TF_VAR_GITHUB_TOKEN:    string
			TF_VAR_ORGANIZATION:    string
		}
		filesystem: "./testdata": read: contents: dagger.#FS
	}

	actions: {
		_run: terraform.#Instance & {
			input: terraform.#Input & {
				source: client.filesystem."./testdata".read.contents
				env: {
					TF_VAR_repo_name:       client.env.TF_VAR_REPO_NAME
					TF_VAR_repo_visibility: client.env.TF_VAR_REPO_VISIBILITY
					TF_VAR_github_token:    client.env.TF_VAR_GITHUB_TOKEN
					TF_VAR_organization:    client.env.TF_VAR_ORGANIZATION
				}
			}
		}

		test: bash.#Run & {
			input:   _run.output.image
			always:  true
			workdir: "/terraform"
			script: contents: #"""
				terraform show
				cat /output/output.json
				"""#
		}
	}
}
