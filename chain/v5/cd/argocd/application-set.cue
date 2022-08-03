package argocd

import (
	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"universe.dagger.io/bash"
	"universe.dagger.io/docker"
	"github.com/h8r-dev/stacks/chain/v5/internal/base"
)

#ApplicationSet: {
	name:       string
	repo:       string
	namespace:  string | *"argocd"
	kubeconfig: dagger.#Secret
	waitFor:    bool | *"true"

	_deps: docker.#Build & {
		steps: [
			base.#Image,
			docker.#Copy & {
				contents: _config.output
				dest:     "/config"
			},
		]
	}

	_config: core.#Source & {
		path: "."
		include: ["application-set.yaml"]
	}

	_sh: core.#Source & {
		path: "."
		include: ["application-set.sh"]
	}

	_run: bash.#Run & {
		env: {
			WAIT_FOR:  "\(waitFor)"
			NAMESPACE: namespace
			NAME:      name
			REPO:      repo
		}
		input: _deps.output
		script: {
			directory: _sh.output
			filename:  "application-set.sh"
		}
		workdir: "/config"
		mounts: config: {
			dest:     "/root/.kube/config"
			contents: kubeconfig
		}
	}
}
