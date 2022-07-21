package repository

import (
	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"universe.dagger.io/bash"
	// "universe.dagger.io/docker"
	"github.com/h8r-dev/stacks/chain/v4/internal/base"
)

#Create: {
	name:         string
	token:        string | dagger.#Secret
	visibility:   string
	organization: string

	wait: _run.success

	_deps: base.#Image
	_sh:   core.#Source & {
		path: "."
		include: ["create-repo.sh"]
	}
	_run: bash.#Run & {
		input:   _deps.output
		workdir: "/workdir"
		env: {
			NAME:         name
			GH_TOKEN:     token
			VISIBILITY:   visibility
			ORGANIZATION: organization
		}
		script: {
			directory: _sh.output
			filename:  "create-repo.sh"
		}
	}
}

#SetSecret: {
	name:         string
	organization: string
	token:        string | dagger.#Secret
	key:          string
	value:        string | dagger.#Secret
	wait:         bool

	_deps: base.#Image
	_sh:   core.#Source & {
		path: "."
		include: ["set-secret.sh"]
	}
	_run: bash.#Run & {
		input:   _deps.output
		workdir: "/workdir"
		env: {
			GH_TOKEN:     token
			NAME:         name
			ORGANIZATION: organization
			KEY:          key
			VALUE:        value
			WAIT:         "\(wait)"
		}
		script: {
			directory: _sh.output
			filename:  "set-secret.sh"
		}
	}
}
