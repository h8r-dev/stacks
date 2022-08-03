package workflow

import (
	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"universe.dagger.io/bash"
	"universe.dagger.io/docker"
	"github.com/h8r-dev/stacks/chain/v5/internal/base"
)

#Generate: {
	appName:        string
	organization:   string
	helmRepo:       string
	wantedFileName: string | *"docker-publish.yaml"

	output: dagger.#FS & _modify.export.directories."/workdir"

	_deps: docker.#Build & {
		steps: [
			base.#Image,
			docker.#Copy & {
				contents: _source.output
				dest:     "/workdir"
			},
		]
	}

	_sh: core.#Source & {
		path: "."
		include: ["modify.sh"]
	}

	_source: core.#Source & {
		path: "template"
	}

	_modify: bash.#Run & {
		input:   _deps.output
		workdir: "/workdir"
		env: {
			ORGANIZATION:     organization
			APP_NAME:         appName
			HELM_REPO:        helmRepo
			WANTED_FILE_NAME: wantedFileName
		}
		script: {
			directory: _sh.output
			filename:  "modify.sh"
		}
		export: directories: "/workdir": _
	}
}
