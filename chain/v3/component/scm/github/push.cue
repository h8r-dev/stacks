package github

import (
	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"universe.dagger.io/bash"
	"github.com/h8r-dev/stacks/chain/v3/internal/base"
)

#GitPush: {
	input: {
		sourceCode:   dagger.#FS
		repository:   string
		organization: string
		githubToken:  dagger.#Secret
	}
	_args: input

	_deps: base.#Image

	_sh: core.#Source & {
		path: "."
		include: ["push.sh"]
	}

	_push: bash.#Run & {
		"input": _deps.output
		workdir: "/workdir"
		env: {
			GITHUB_TOKEN:        _args.githubToken
			GITHUB_REPO:         _args.repository
			GITHUB_ORGANIZATION: input.organization
			GIT_USER:            "heighliner"
			GIT_EMAIL:           "h8r@h8r.io"
		}
		mounts: sourcecode: {
			type:     "fs"
			dest:     "/workdir"
			contents: input.sourceCode
		}
		script: {
			directory: _sh.output
			filename:  "push.sh"
		}
	}

}
