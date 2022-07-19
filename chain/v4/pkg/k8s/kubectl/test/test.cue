package test

import (
	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"github.com/h8r-dev/stacks/chain/v4/pkg/k8s/kubectl"
	"github.com/h8r-dev/stacks/chain/v4/pkg/k8s/kubeconfig"
)

dagger.#Plan & {
	client: {
		commands: kubeconfig: {
			name: "cat"
			args: [env.KUBECONFIG]
			stdout: dagger.#Secret
		}
		env: KUBECONFIG: string
	}
	actions: test: {
		_transformKubeconfig: kubeconfig.#TransformToInternal & {
			input: kubeconfig: client.commands.kubeconfig.stdout
		}
		_kubeconfig: _transformKubeconfig.output.kubeconfig

		_manifests: core.#WriteFile & {
			input: dagger.#Scratch
			path:  "/manifest.yaml"
			contents: """
				apiVersion: v1
				kind: ConfigMap
				metadata:
				  name: test-from-fs
				data:
				  from: fs
				"""
		}

		_applyFS: kubectl.#Apply & {
			input: {
				kubeconfig: _kubeconfig
				namespace:  "test"
				contents:   _manifests.output
			}
		}

		_applyURL: kubectl.#Apply & {
			input: {
				kubeconfig: _kubeconfig
				type:       "url"
				contents:   "https://k8s.io/examples/application/nginx/nginx-svc.yaml"
			}
		}

		_applyFile: kubectl.#Apply & {
			input: {
				kubeconfig: _kubeconfig
				namespace:  "test"
				contents: """
					apiVersion: v1
					kind: ConfigMap
					metadata:
					  name: test-from-file
					data:
					  from: file
					"""
			}
		}
	}
}
