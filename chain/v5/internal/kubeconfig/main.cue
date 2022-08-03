package kubeconfig

import (
	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"universe.dagger.io/bash"
	"github.com/h8r-dev/stacks/chain/v5/internal/base"
)

// TransformToInternal transforms the given kubeconfig to internal cluster address
#TransformToInternal: {
	input: kubeconfig: dagger.#Secret

	output: {
		kubeconfig: dagger.#Secret
		apiServer:  string
	}

	_baseImage: base.#Image

	_kubeconfig: input.kubeconfig

	_sh: core.#Source & {
		path: "."
		include: ["run.sh"]
	}

	_run: bash.#Run & {
		always: true
		input:  _baseImage.output
		mounts: kubeconfig: {
			dest:     "/kubeconfig"
			contents: _kubeconfig
			mask:     0o022
		}
		script: {
			directory: _sh.output
			filename:  "run.sh"
		}
		export: {
			secrets: {
				"/new_kubeconfig":     dagger.#Secret
				"/origina_kubeconfig": dagger.#Secret
			}
			files: "/api_server": string
		}
	}

	output: {
		kubeconfig:         _run.export.secrets."/new_kubeconfig"
		originalKubeconfig: _run.export.secrets."/origina_kubeconfig"
		apiServer:          _run.export.files."/api_server"
	}
}
