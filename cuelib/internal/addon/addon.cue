package addon

import (
	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"universe.dagger.io/bash"

	"github.com/h8r-dev/stacks/cuelib/internal/base"
)

#Read: {

	input: kubeconfig: dagger.#Secret

	prometheus:    _do.export.files."/prometheus.yaml"
	grafana:       _do.export.files."/grafana.yaml"
	loki:          _do.export.files."/loki.yaml"
	alertManager:  _do.export.files."/alert-manager.yaml"
	argoCD:        _do.export.files."/argo-cd.yaml"
	sealedSecrets: _do.export.files."/sealed-secrets.yaml"
	dapr:          _do.export.files."/dapr.yaml"

	_baseImage: base.#Image

	_sh: core.#Source & {
		path: "."
		include: ["read-config.sh"]
	}

	_args: kubeconfig: input.kubeconfig

	_do: bash.#Run & {
		always:  true
		input:   _baseImage.output
		workdir: "/workdir"
		mounts: kubeconfig: {
			dest:     "/root/.kube/config"
			contents: _args.kubeconfig
		}
		script: {
			directory: _sh.output
			filename:  "read-config.sh"
		}
		export: files: {
			"/prometheus.yaml":     string
			"/grafana.yaml":        string
			"/loki.yaml":           string
			"/alert-manager.yaml":  string
			"/argo-cd.yaml":        string
			"/sealed-secrets.yaml": string
			"/dapr.yaml":           string
		}
	}
}
