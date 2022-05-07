package test

import (
	"dagger.io/dagger"
	"github.com/h8r-dev/stacks/chain/ingress/nginx/cloud"
)

dagger.#Plan & {
	client: {
		commands: kubeconfig: {
			name: "cat"
			args: ["\(env.KUBECONFIG)"]
			stdout: dagger.#Secret
		}
		env: KUBECONFIG: string
	}

	actions: test: cloud.#Instance & {
		#IngressNginxSetting: #"""
			controller:
			  service:
			    type: NodePort
			  metrics:
			    enabled: true
			  podAnnotations:
			    prometheus.io/scrape: "true"
			    prometheus.io/port: "10254"
			"""#

		input: cloud.#Input & {
			kubeconfig: client.commands.kubeconfig.stdout
			version:    "4.0.19"
			values:     #IngressNginxSetting
		}
	}
}
