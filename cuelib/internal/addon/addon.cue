package addon

import (
	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"universe.dagger.io/bash"

	"github.com/h8r-dev/stacks/cuelib/internal/base"
)

#ReadInfraConfig: {

	input: kubeconfig: dagger.#Secret

	prometheus:    _do.export.secrets."/prometheus.yaml"
	grafana:       _do.export.secrets."/grafana.yaml"
	loki:          _do.export.secrets."/loki.yaml"
	alertManager:  _do.export.secrets."/alert-manager.yaml"
	argoCD:        _do.export.secrets."/argo-cd.yaml"
	sealedSecrets: _do.export.secrets."/sealed-secrets.yaml"
	dapr:          _do.export.secrets."/dapr.yaml"

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
		export: secrets: {
			"/prometheus.yaml":     dagger.#Secret
			"/grafana.yaml":        dagger.#Secret
			"/loki.yaml":           dagger.#Secret
			"/alert-manager.yaml":  dagger.#Secret
			"/argo-cd.yaml":        dagger.#Secret
			"/sealed-secrets.yaml": dagger.#Secret
			"/dapr.yaml":           dagger.#Secret
		}
	}
}
