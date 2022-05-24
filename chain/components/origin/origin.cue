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
			chart: "kube-prometheus-stack"
			url:   "https://prometheus-community.github.io/helm-charts"
		}
		internal: {
			chart: "kube-prometheus-stack"
			url:   "https://h8r-helm.pkg.coding.net/release/helm"
		}
	}
	loki: {
		global: {
			chart: "loki-stack"
			url:   "https://grafana.github.io/helm-charts"
		}
		internal: {
			chart: "loki-stack"
			url:   "https://h8r-helm.pkg.coding.net/release/helm"
		}
	}
	nocalhost: {
		global: {
			chart: "nocalhost"
			url:   "https://nocalhost.github.io/charts"
		}
		internal: {
			chart: "nocalhost"
			url:   "https://h8r-helm.pkg.coding.net/release/helm"
		}
	}
	dapr: {
		global: {
			chart: "dapr"
			url:   "https://dapr.github.io/helm-charts"
		}
		internal: {
			chart: "dapr"
			url:   "https://h8r-helm.pkg.coding.net/release/helm"
		}
	}
}
