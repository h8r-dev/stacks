package main

import (
	"dagger.io/dagger"
	"github.com/h8r-dev/cuelib/deploy/helm"
	"github.com/h8r-dev/cuelib/network/ingress"
	"github.com/h8r-dev/cuelib/monitoring/grafana"
	"github.com/h8r-dev/cuelib/cd/argocd"
	"github.com/h8r-dev/cuelib/deploy/kubectl"
	"github.com/h8r-dev/cuelib/monitoring/prometheus"
	"github.com/h8r-dev/cuelib/h8r/h8r"
	"github.com/h8r-dev/cuelib/dev/nocalhost"
	"github.com/h8r-dev/cuelib/scm/github"
	"github.com/h8r-dev/cuelib/framework/react/next"
	githubAction "github.com/h8r-dev/cuelib/ci/github"
)

dagger.#Plan & {
	client: {
		filesystem: {
			code: read: contents: dagger.#FS
			// "./output.yaml": write: {
			//  // Convert a CUE value into a YAML formatted string
			//  contents: actions.up.outputYaml.output
			// }
		}
		commands: kubeconfig: {
			name: "cat"
			args: ["\(env.KUBECONFIG)"]
			stdout: dagger.#Secret
		}
		env: {
			KUBECONFIG:   string
			APP_NAME:     string
			ORGANIZATION: string
			GITHUB_TOKEN: dagger.#Secret
		}
	}

	actions: up: {

	}
}
