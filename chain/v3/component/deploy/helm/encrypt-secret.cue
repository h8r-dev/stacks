package helm

import (
	"strings"
	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"universe.dagger.io/bash"
	"universe.dagger.io/docker"
	"github.com/h8r-dev/stacks/chain/v3/internal/base"
)

#EncryptSecret: {
	input: {
		name:       string
		chart:      dagger.#FS
		username:   string
		password:   dagger.#Secret
		kubeconfig: dagger.#Secret
	}

	output: {
		chart:   dagger.#FS
		success: bool | *true
	}

	_deps: docker.#Build & {
		steps: [
			base.#Image,
			docker.#Copy & {
				contents: input.chart
				dest:     "/helm"
			},
		]
	}

	_sh: core.#Source & {
		path: "."
		include: ["encrypt-secret.sh"]
	}

	_run: bash.#Run & {
		env: {
			USERNAME: strings.ToLower(input.username)
			PASSWORD: input.password
			APP_NAME: input.name
		}
		"input": _deps.output
		workdir: "/helm"
		script: {
			directory: _sh.output
			filename:  "encrypt-secret.sh"
		}
		if input.kubeconfig != _|_ {
			mounts: kubeconfig: {
				dest:     "/kubeconfig"
				contents: input.kubeconfig
			}
		}
		export: directories: "/helm": _
	}
	output: chart: _run.export.directories."/helm"
}
