package test

import (
	"dagger.io/dagger"
	"github.com/h8r-dev/stacks/chain/components/ci/github"
	"github.com/h8r-dev/stacks/chain/internal/utils/base"
	"universe.dagger.io/bash"
)

dagger.#Plan & {
	actions: {
		_baseImage: base.#Image & {}

		_repoName: "hello"

		add_ci_files: github.#Instance & {
			input: github.#Input & {
				image:        _baseImage.output
				name:         _repoName
				organization: "hello-org"
				appName:      "hello-app"
				deployRepo:   "github@fawef.com/fawef/fawef-deploy"
			}
		}

		test: bash.#Run & {
			input: add_ci_files.output.image
			script: contents: """
        cd /scaffold/\(_repoName)
        ls -alh .github/workflows/docker-publish.yaml
        cat .github/workflows/docker-publish.yaml
      """
		}
	}
}
