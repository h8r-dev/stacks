package state

import (
	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"github.com/h8r-dev/stacks/chain/internal/deploy/kubectl"
	"github.com/h8r-dev/stacks/chain/internal/utils/base"
	"universe.dagger.io/bash"
	"universe.dagger.io/docker"
)

#Store: {
	namespace:  string
	kubeconfig: dagger.#Secret
	waitFor:    bool | *"true"

	src: core.#Source & {
		path: "."
	}

	manifest: core.#ReadFile & {
		input: src.output
		path:  "./default-infra-output.yaml"
	}

	run: kubectl.#Manifest & {
		"waitFor":    waitFor
		"manifest":   manifest.contents
		"namespace":  namespace
		"kubeconfig": kubeconfig
	}
}

#SetConfigMap: {
	namespace:  string | *"heighliner-infra"
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
		include: ["config.yaml"]
	}

	_sh: core.#Source & {
		path: "."
		include: ["set-config.sh"]
	}

	_run: bash.#Run & {
		env: {
			WAIT_FOR:  "\(waitFor)"
			NAMESPACE: namespace
		}
		input: _deps.output
		script: {
			directory: _sh.output
			filename:  "set-config.sh"
		}
		workdir: "/config"
		mounts: config: {
			dest:     "/root/.kube/config"
			contents: kubeconfig
		}
	}
}
