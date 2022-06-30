package helm

import (
	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"universe.dagger.io/bash"
	"universe.dagger.io/docker"
	"github.com/h8r-dev/stacks/chain/v3/internal/base"
)

#InstallOrUpgrade: {
	input: {
		name:       string
		version:    string | *""
		namespace:  string
		set:        string | *""
		waitFor:    bool | *true
		wait:       bool | *false
		kubeconfig: dagger.#Secret
		{
			type:  "repo"
			repo:  string
			chart: string
			_env: {
				REPO:  repo
				CHART: chart
			}
		} | {
			type:  "local"
			path:  string | *"/"
			chart: dagger.#FS
			_env: CHART_PATH: path
		}
	}

	output: success: bool | *true

	_deps: docker.#Build & {
		steps: [
			base.#Image,
			if (input.chart & dagger.#FS) != _|_ {
				docker.#Copy & {
					contents: input.chart
					dest:     "/helm"
				}
			},
		]
	}

	_sh: core.#Source & {
		path: "."
		include: ["install-or-upgrade.sh"]
	}

	_run: bash.#Run & {
		env: {
			NAME:      input.name
			VERSION:   input.version
			NAMESPACE: input.namespace
			SET:       input.set
			WAIT:      "\(input.wait)"
			WAIT_FOR:  "\(input.waitFor)"
			input._env
		}
		"input": _deps.output
		workdir: "/helm"
		script: {
			directory: _sh.output
			filename:  "install-or-upgrade.sh"
		}
		if input.kubeconfig != _|_ {
			mounts: config: {
				dest:     "/root/.kube/config"
				contents: input.kubeconfig
			}
		}
	}
	output: success: _run.success
}
