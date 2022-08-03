package kubectl

import (
	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"universe.dagger.io/bash"
	"universe.dagger.io/docker"
	"github.com/h8r-dev/stacks/chain/v5/internal/base"
)

#Apply: {
	input: {
		kubeconfig: dagger.#Secret
		namespace:  string | *""
		wait:       bool | *false
		waitFor:    bool | *true
		// manifest yaml, url, fs
		contents: string | dagger.#FS
		// The `type` parameter is required, if the manifest tpye is url. More info, see test.
		type: *"manifest" | "url" | "fs"
	}

	output: success: _apply.success

	_args: input

	_deps: docker.#Build & {
		steps: [
			base.#Image,
			if (_args.contents & dagger.#FS) != _|_ {
				docker.#Copy & {
					contents: _args.contents
					dest:     "/workdir"
				}
			},
			if (_args.contents & string) != _|_ {
				_manifest: core.#WriteFile & {
					input:    dagger.#Scratch
					contents: _args.contents
					path:     "/manifest.yaml"
				}
				docker.#Copy & {
					contents: _manifest.output
					dest:     "/workdir"
				}
			},
		]
	}

	_kubeconfig: input.kubeconfig

	_sh: core.#Source & {
		path: "."
		include: ["apply.sh"]
	}

	_apply: bash.#Run & {
		env: {
			NAMESPACE: _args.namespace
			WAIT:      "\(_args.wait)"
			WAIT_FOR:  "\(_args.waitFor)"
			TYPE:      _args.type
		}
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
			filename:  "apply.sh"
		}
	}
}
