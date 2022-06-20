package crd

import (
	"dagger.io/dagger"
	"dagger.io/dagger/core"

	"github.com/h8r-dev/stacks/chain/v3/pkg/kubectl/apply"
)

#CreateCloudCRD: {
	input: {
		remote:     string | *"https://github.com/h8r-dev/cloud-crd.git"
		ref:        string | *"main"
		kubeconfig: dagger.#Secret
	}

	_pull: core.#GitPull & {
		remote: input.remote
		ref:    input.ref
	}

	_crdFile: core.#Subdir & {
		input: _pull.output
		path:  "/config/crd/bases"
	}

	_apply: apply.#Dir & {
		"input": {
			kubeconfig: input.kubeconfig
			manifests:  _crdFile.output
		}
	}
}
