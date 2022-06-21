package apply

import (
	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"github.com/h8r-dev/stacks/chain/v3/internal/base"
	"universe.dagger.io/bash"
	"universe.dagger.io/docker"
)

#File: {
	input: {
		kubeconfig: dagger.#Secret
		contents:   string
	}

	_args: input

	_deps: {
		_base:    base.#Image
		_makeDir: core.#Mkdir & {
			input: _base.output.rootfs
			path:  "/workdir/source"
		}
		_writeManifest: core.#WriteFile & {
			input:    _makeDir.output
			path:     "/workdir/source/manifest.yaml"
			contents: _args.contents
		}
		output: docker.#Image & {
			rootfs: _writeManifest.output
			config: _base.output.config
		}
	}

	_kubeconfig: input.kubeconfig

	_sh: core.#Source & {
		path: "."
		include: ["run.sh"]
	}

	_file: bash.#Run & {
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
