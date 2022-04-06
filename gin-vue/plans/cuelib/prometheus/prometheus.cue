package prometheus

import (
	//"strings"
	"dagger.io/dagger"
	"github.com/h8r-dev/cuelib/helm"
	"github.com/h8r-dev/cuelib/kubectl"
	"github.com/h8r-dev/cuelib/h8r"
	"github.com/h8r-dev/cuelib/ingress"
)

// need to wait for ingress nginx installed
#installPrometheusStack: {
	uri:                string
	kubeconfig:         string | dagger.#Secret
	ingressVersion:     string
	prometheusDomain:   string
	grafanaDomain:      string
	alertmanagerDomain: string
	host:               string
	name:               string
	namespace:          string
	waitFor:            bool

	kubePrometheus: helm.#Chart & {
		"name":       name
		repository:   "https://prometheus-community.github.io/helm-charts"
		chart:        "kube-prometheus-stack"
		action:       "installOrUpgrade"
		"namespace":  namespace
		"kubeconfig": kubeconfig
		wait:         true
		"waitFor":    waitFor
	}

	alertmanagerIngress: {
		alertIngress: ingress.#Ingress & {
			name:               uri + "-alertmanager"
			className:          "nginx"
			hostName:           alertmanagerDomain
			path:               "/"
			"namespace":        namespace
			backendServiceName: "alertmanager-operated"
			backendServicePort: 9093
			"ingressVersion":   ingressVersion
		}

		deploy: kubectl.#Manifest & {
			"kubeconfig": kubeconfig
			manifest:     alertIngress.manifestStream
			"namespace":  namespace
			"waitFor":    waitFor
		}

		createH8rIngress: h8r.#CreateH8rIngress & {
			name:   uri + "-alertmanager"
			"host": host
			domain: alertmanagerDomain
			port:   "80"
		}

		success: deploy.success
	}

	prometheusIngress: {
		promIngress: ingress.#Ingress & {
			name:               uri + "-prometheus"
			className:          "nginx"
			hostName:           prometheusDomain
			path:               "/"
			"namespace":        namespace
			backendServiceName: "prometheus-operated"
			backendServicePort: 9090
			"ingressVersion":   ingressVersion
		}

		deploy: kubectl.#Manifest & {
			"kubeconfig": kubeconfig
			manifest:     promIngress.manifestStream
			"namespace":  namespace
			"waitFor":    waitFor
		}

		createH8rIngress: h8r.#CreateH8rIngress & {
			name:   uri + "-prometheus"
			"host": host
			domain: prometheusDomain
			port:   "80"
		}

		success: deploy.success
	}

	grafanaIngress: {
		grafanaIngress: ingress.#Ingress & {
			"name":             uri + "-grafana"
			className:          "nginx"
			hostName:           grafanaDomain
			path:               "/"
			"namespace":        namespace
			backendServiceName: name + "-grafana"
			"ingressVersion":   ingressVersion
		}

		deploy: kubectl.#Manifest & {
			"kubeconfig": kubeconfig
			manifest:     grafanaIngress.manifestStream
			"namespace":  namespace
			"waitFor":    waitFor
		}

		createH8rIngress: h8r.#CreateH8rIngress & {
			name:   uri + "-grafana"
			"host": host
			domain: grafanaDomain
			port:   "80"
		}

		success: deploy.success
	}

	success: kubePrometheus.success & prometheusIngress.success & grafanaIngress.success & alertmanagerIngress.success
}

#installLokiStack: {
	namespace:  string
	kubeconfig: string | dagger.#Secret
	install:    helm.#Chart & {
		name:         "loki"
		repository:   "https://grafana.github.io/helm-charts"
		chart:        "loki-stack"
		action:       "installOrUpgrade"
		"namespace":  namespace
		"kubeconfig": kubeconfig
		wait:         true
	}

	success: install.success
}
