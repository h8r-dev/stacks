package apply

import (
	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"github.com/h8r-dev/stacks/chain/v3/internal/base"
	"universe.dagger.io/bash"
	"universe.dagger.io/docker"
)

#Dir: {
	input: {
		kubeconfig: dagger.#Secret
		manifests:  dagger.#FS
	}

	_deps: docker.#Build & {
		steps: [
			base.#Image,
			docker.#Copy & {
				contents: input.manifests
				dest:     "/workdir/source"
			},
		]
	}

	_kubeconfig: input.kubeconfig

	_sh: core.#Source & {
		path: "."
		include: ["run.sh"]
	}

	_dir: bash.#Run & {
		always:  true
		input:   _deps.output
		workdir: "/workdir"
		mounts: kubeconfig: {
			dest:     "/root/.kube/config"
			contents: _kubeconfig
			mask:     0o022
		}
		script: {
			directory: _sh.output
			filename:  "run.sh"
		}
	}
}
