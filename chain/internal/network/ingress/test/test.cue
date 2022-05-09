package ingress

import (
	"dagger.io/dagger"
	"github.com/h8r-dev/stacks/chain/internal/network/ingress"
	"github.com/h8r-dev/stacks/chain/internal/deploy/helm"
)

ingressNginxSetting: #"""
	controller:
	  service:
	    type: LoadBalancer
	  metrics:
	    enabled: true
	  podAnnotations:
	    prometheus.io/scrape: "true"
	    prometheus.io/port: "10254"
	"""#

dagger.#Plan & {
	client: {
		commands: kubeconfig: {
			name: "cat"
			args: ["\(env.KUBECONFIG)"]
			stdout: dagger.#Secret
		}
		env: KUBECONFIG: string
	}

	actions: test: {
		kubeconfig: client.commands.kubeconfig.stdout

		installIngress: helm.#Chart & {
			name:         "ingress-nginx"
			repository:   "https://h8r-helm.pkg.coding.net/release/helm"
			chart:        "ingress-nginx"
			namespace:    "ingress-nginx"
			action:       "installOrUpgrade"
			"kubeconfig": kubeconfig
			values:       ingressNginxSetting
			wait:         true
		}

		ingressVersion: ingress.#GetIngressVersion & {
			"kubeconfig": kubeconfig
		}

		ingressEndpoint: ingress.#GetIngressEndpoint & {
			"kubeconfig": kubeconfig
		}
	}
}
