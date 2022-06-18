package state

import (
	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"universe.dagger.io/bash"
	"github.com/h8r-dev/stacks/chain/v3/internal/base"
	// "github.com/h8r-dev/stacks/chain/v3/pkg/kubectl/apply"
)

#Write: {
	input: kubeconfig: dagger.#Secret

	_args: input

	_deps: base.#Image

	_pullSh: core.#Source & {
		path: "."
		include: ["pull-crd.sh"]
	}

	_pullTemplate: bash.#Run & {
		input:   _deps.output
		workdir: "/workdir"
		script: {
			directory: _pullSh.output
		}
	}

	_sh: core.#Source & {
		path: "."
		include: ["pull-crd.sh"]
	}

	_write: bash.#Run & {
		always:  true
		input:   _deps.output
		workdir: "/workdir"
		mounts: kubeconfig: {
			dest:     "/root/.kube/config"
			contents: _args.kubeconfig
		}
		script: {
			directory: _sh.output
			filename:  "write-state.sh"
		}
	}
}
