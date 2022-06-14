package addon

import (
	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"universe.dagger.io/bash"

	"github.com/h8r-dev/stacks/cuelib/internal/base"
)

#Read: {

	input: kubeconfig: dagger.#Secret

	_componentsList: [
		{
			name: "prometheus"
			dir:  "/prometheus"
		},
		{
			name: "grafana"
			dir:  "/grafana"
		},
		{
			name: "loki"
			dir:  "/loki"
		},
		{
			name: "alertManager"
			dir:  "/alert-manager"
		},
		{
			name: "argoCD"
			dir:  "argo-cd"
		},
		{
			name: "dapr"
			dir:  "/dapr"
		},
	]

	for c in _componentsList {
		(c.name): _#component & {
			_input: {
				files: _do.export.files
				dir:   c.dir
			}
		}
	}
	sealedSecrets: {
		enabled: _do.export.files."/sealed-secrets/enabled.txt"
		tlscrt:  _do.export.files."/sealed-secrets/tlscrt.txt"
		tlskey:  _do.export.files."/sealed-secrets/tlskey.txt"
	}

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
			for c in _componentsList {
				"\(c.dir)/enabled.txt":     string
				"\(c.dir)/url.txt":         string
				"\(c.dir)/namespace.txt":   string
				"\(c.dir)/ingress.txt":     string
				"\(c.dir)/credentials.txt": string
				"\(c.dir)/annotations.txt": string
			}
			"/sealed-secrets/enabled.txt": string
			"/sealed-secrets/tlscrt.txt":  string
			"/sealed-secrets/tlskey.txt":  string
		}
	}
}

_#component: {
	_input: {
		files: _
		dir:   string
	}

	enabled:     _input.files["\(_input.dir)/enabled.txt"]
	url:         _input.files["\(_input.dir)/url.txt"]
	namespace:   _input.files["\(_input.dir)/namespace.txt"]
	ingress:     _input.files["\(_input.dir)/ingress.txt"]
	credentials: _input.files["\(_input.dir)/credentials.txt"]
	annotations: _input.files["\(_input.dir)/annotations.txt"]
}
