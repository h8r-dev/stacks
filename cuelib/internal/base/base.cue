package base

import (
	"universe.dagger.io/docker"
)

#Image: {
	docker.#Pull & {
		source: "heighlinerdev/stack-base:debian"
	}
}

#HelmStarter: {
	url:      string | *"https://github.com/h8r-dev/helm-starter.git"
	repoName: string | *"helm-starter"
	version:  string | *"main"
}

#DefaultDomain: {
	application: {
		domain:              string | *"h8r.site"
		productionNamespace: "production"
	}
	infra: {
		domain:       string | *"h8r.site"
		argocd:       "argocd." + domain
		prometheus:   "prometheus." + domain
		alertManager: "alert." + domain
		grafana:      "grafana." + domain
		nocalhost:    "nocalhost." + domain
		dapr:         "dapr." + domain
	}
}

HelmStarter: {
	gin:  "helm-starter/go/gin"
	next: "helm-starter/nodejs/node"
}
