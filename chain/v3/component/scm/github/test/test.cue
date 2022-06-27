package test

import (
	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"github.com/h8r-dev/stacks/chain/v3/component/scm/github"
)

dagger.#Plan & {
	client: {
		commands: kubeconfig: {
			name: "cat"
			args: [env.KUBECONFIG]
			stdout: dagger.#Secret
		}
		env: {
			ORGANIZATION: string
			GITHUB_TOKEN: dagger.#Secret
			KUBECONFIG:   string
		}
	}
	actions: test: github.#Push & {
		_sourceCode: core.#Source & {
			path: "."
			include: ["README.md"]
		}
		input: github.#Input & {
			repositoryName:      "stack-test-repo"
			contents:            _sourceCode.output
			visibility:          "private"
			kubeconfig:          client.commands.kubeconfig.stdout
			organization:        client.env.ORGANIZATION
			personalAccessToken: client.env.GITHUB_TOKEN
		}
	}

	actions: testpull: github.#Pull & {
		input: github.#Input & {
			repositoryName:      "hello-world-30-deploy"
			organization:        client.env.ORGANIZATION
			personalAccessToken: client.env.GITHUB_TOKEN
		}
	}
}
