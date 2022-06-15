package origin

#Origin: {
	dashboard: {
		global: {
			chart: "heighliner-cloud"
			url:   "https://h8r-helm.pkg.coding.net/release/helm"
		}
		internal: {
			chart: "heighliner-cloud"
			url:   "https://h8r-helm.pkg.coding.net/release/helm"
		}
	}
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
	sealedSecrets: {
		global: {
			chart: "sealed-secrets"
			url:   "https://bitnami-labs.github.io/sealed-secrets"
		}
		internal: {
			chart: "sealed-secrets"
			url:   "https://h8r-helm.pkg.coding.net/release/helm"
		}
	}
}
