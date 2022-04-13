package prometheus

import (
	"dagger.io/dagger"
	"github.com/h8r-dev/cuelib/monitoring/prometheus"
	"github.com/h8r-dev/cuelib/deploy/helm"
	"github.com/h8r-dev/cuelib/network/ingress"
	"github.com/h8r-dev/cuelib/utils/random"
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
		randomString: random.#String & {

		}

		uri: randomString.output

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

		prom: prometheus.#InstallPrometheusStack & {
			"uri":              uri
			"kubeconfig":       kubeconfig
			"ingressVersion":   ingressVersion.content
			prometheusDomain:   uri + ".prom.stack.h8r.io"
			grafanaDomain:      uri + ".grafana.stack.h8r.io"
			alertmanagerDomain: uri + ".alert.stack.h8r.io"
			host:               ingressEndpoint.content
			name:               "prometheus"
			namespace:          "monitoring"
			waitFor:            installIngress.success
		}
	}
}
