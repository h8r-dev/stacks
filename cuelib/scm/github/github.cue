package github

import (
	"universe.dagger.io/bash"
	"universe.dagger.io/docker"
	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"strings"
	"github.com/h8r-dev/stacks/cuelib/internal/utils/base"
)

#Input: {
	repositoryName:      string
	contents:            dagger.#FS
	personalAccessToken: dagger.#Secret
	organization:        string
	visibility:          string
	kubeconfig:          dagger.#Secret
	gitInitBranch:       string | *"main"
	gitUserName:         string | *"heighliner"
	gitUserEmail:        string | *"heighliner@h8r.dev"
}

#Push: {
	input: #Input & {
		contents: _mockSourceCode.output
	}

	_mockSourceCode: core.#Source & {
		path: "test"
		include: ["README.md"]
	}

	_tfScript: core.#Source & {
		path: "terraform"
		include: ["main.tf", "provider.tf", "variables.tf"]
	}

	_deps: docker.#Build & {
		steps: [
			base.#Image,
			docker.#Copy & {
				contents: input.contents
				dest:     "/workdir/source"
			},
			docker.#Copy & {
				contents: _tfScript.output
				dest:     "/workdir/terraform"
			},
		]
	}

	_sh: core.#Source & {
		path: "."
		include: ["create-github-repo.sh"]
	}

	_push: bash.#Run & {
		"input": _deps.output
		workdir: "/workdir"
		always:  true
		env: {
			REPOSITORY_NAME:     input.repositoryName
			GITHUB_TOKEN:        input.personalAccessToken
			GITHUB_ORGANIZATION: input.organization
			VISIBILITY:          input.visibility
			// for terraform
			TF_VAR_github_token:  input.personalAccessToken
			TF_VAR_organization:  input.organization
			TF_VAR_namespace:     "default"
			TF_VAR_secret_suffix: strings.ToLower(input.organization)
			// config values
			GIT_INIT_BRANCH: input.gitInitBranch
			GIT_USER_NAME:   input.gitUserName
			GIT_USER_EMAIL:  input.gitUserEmail
		}
		mounts: kubeconfig: {
			dest:     "/root/.kube/config"
			contents: input.kubeconfig
		}
		script: {
			directory: _sh.output
			filename:  "create-github-repo.sh"
		}
	}
}
