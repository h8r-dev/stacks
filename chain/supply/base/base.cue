package base

#Addons: {
	name:     string | "prometheus" | "loki" | "nocalhost" | "ingress-nginx"
	version?: string
}

#Repository: {
	// Repository name
	// RFC 1035: https://tools.ietf.org/html/rfc1035
	name: =~"^[a-zA-Z]([a-zA-Z0-9-]*[a-zA-Z0-9])?(\\.[a-zA-Z]([a-zA-Z0-9-]*[a-zA-Z0-9])?)*$"

	// Repository type
	type: string | *"frontend" | "backend" | "deploy"

	// Framework
	framework: string | *"gin" | "helm" | "next" | "react" | "vue"

	// CI
	ci: string | *"github"

	// Helm set values
	// Format: '.image.repository = "rep" | .image.tag = "tag"'
	set?: string | *""

	registry: string | *"github"

	// extraArgs use for helm set now
	extraArgs?: {...}
}

#DefaultDomain: {
	application: {
		domain:              ".h8r.application"
		productionNamespace: "production"
	}
	infra: {
		domain:       ".h8r.infra"
		argocd:       "argocd" + domain
		prometheus:   "prometheus" + domain
		alertManager: "alert" + domain
		grafana:      "grafana" + domain
		nocalhost:    "nocalhost" + domain
	}
}

#DefaultInternalDomain: {
	application: {
		domain:              ""
		productionNamespace: "production"
	}
	infra: {
		domain:       ".svc"
		argocd:       "argocd-server.argocd" + domain
		prometheus:   "prometheus" + domain
		alertManager: "alert" + domain
		grafana:      "grafana" + domain
		nocalhost:    "nocalhost" + domain
	}
}
