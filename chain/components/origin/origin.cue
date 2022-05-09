package origin

#Origin: {
	argocd: {
		global: {
			version: "v2.3.3"
			url:     "https://raw.githubusercontent.com/argoproj/argo-cd/\(version)/manifests/install.yaml"
		}
		internal: {
			version: "v2.3.3"
			url:     "https://raw.githubusercontent.com/argoproj/argo-cd/\(version)/manifests/install.yaml"
		}
	}
	prometheus: {
		global: {
			chart:   "kube-prometheus-stack"
			version: "34.9.0"
			url:     "https://prometheus-community.github.io/helm-charts"
		}
		internal: {
			chart:   "kube-prometheus-stack"
			version: "34.9.0"
			url:     "https://prometheus-community.github.io/helm-charts"
		}
	}
	loki: {
		global: {
			chart:   "loki-stack"
			version: "2.6.2"
			url:     "https://grafana.github.io/helm-charts"
		}
		internal: {
			chart:   "loki-stack"
			version: "2.6.2"
			url:     "https://prometheus-community.github.io/helm-charts"
		}
	}
	nocalhost: {
		global: {
			chart:   "nocalhost"
			version: "0.6.16"
			url:     "https://nocalhost.github.io/charts"
		}
		internal: {
			chart:   "nocalhost"
			version: "0.6.16"
			url:     "https://nocalhost.github.io/charts"
		}
	}
}
