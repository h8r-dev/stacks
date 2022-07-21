package git

import (
	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"universe.dagger.io/bash"
	"universe.dagger.io/docker"
	"github.com/h8r-dev/stacks/chain/v4/internal/base"
)

#Pull: {
	remote: string
	ref:    string
	token:  string | dagger.#Secret
	output: dagger.#FS & _run.export.directories."/workdir/source"

	_deps: base.#Image
	_sh:   core.#Source & {
		path: "."
		include: ["pull.sh"]
	}
	_run: bash.#Run & {
		input:   _deps.output
		always:  true
		workdir: "/workdir"
		env: {
			REMOTE: remote
			REF:    ref
			TOKEN:  token
		}
		script: {
			directory: _sh.output
			filename:  "pull.sh"
		}
		export: directories: "/workdir/source": _
	}
}

#Push: {
	name:         string
	organization: string
	token:        string | dagger.#Secret
	input:        dagger.#FS

	_deps: docker.#Build & {
		steps: [
			base.#Image,
			docker.#Copy & {
				contents: input
				dest:     "/workdir"
			},
		]
	}
	_sh: core.#Source & {
		path: "."
		include: ["push.sh"]
	}
	_run: bash.#Run & {
		input:   _deps.output
		workdir: "/workdir"
		env: {
			NAME:         name
			ORGANIZATION: organization
			TOKEN:        token
		}
		script: {
			directory: _sh.output
			filename:  "push.sh"
		}
	}
}

#PR: {
	name:         string
	organization: string
	token:        string | dagger.#Secret
	input:        dagger.#FS

	_deps: docker.#Build & {
		steps: [
			base.#Image,
			docker.#Copy & {
				contents: input
				dest:     "/workdir"
			},
		]
	}
	_sh: core.#Source & {
		path: "."
		include: ["pr.sh"]
	}
	_run: bash.#Run & {
		input:   _deps.output
		workdir: "/workdir"
		env: {
			NAME:         name
			ORGANIZATION: organization
			GH_TOKEN:     token
		}
		script: {
			directory: _sh.output
			filename:  "pr.sh"
		}
	}
}

#Init: {
	input:  dagger.#FS
	output: _run.export.directories."/workdir"

	_deps: docker.#Build & {
		steps: [
			base.#Image,
			docker.#Copy & {
				contents: input
				dest:     "/workdir"
			},
		]
	}
	_sh: core.#Source & {
		path: "."
		include: ["init.sh"]
	}
	_run: bash.#Run & {
		input:   _deps.output
		workdir: "/workdir"
		script: {
			directory: _sh.output
			filename:  "init.sh"
		}
		export: directories: "/workdir": _
	}
}
