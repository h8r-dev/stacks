package nocalhost

import (
	"dagger.io/dagger"
	"github.com/h8r-dev/stacks/chain/internal/deploy/helm"
	"github.com/h8r-dev/stacks/chain/internal/deploy/kubectl"
	"github.com/h8r-dev/stacks/chain/internal/network/ingress"
)

// install nocalhost
#Install: {
	namespace:      string | *"nocalhost"
	svcName:        string | *"nocalhost-web"
	uri:            string
	kubeconfig:     string | dagger.#Secret
	ingressVersion: string
	domain:         string
	name:           string

	waitFor?:     bool
	chartVersion: string

	helmInstall: helm.#Chart & {
		"name":         name
		repository:     "https://nocalhost.github.io/charts"
		chart:          "nocalhost"
		"namespace":    namespace
		"kubeconfig":   kubeconfig
		"chartVersion": chartVersion
		set:            "service.type=ClusterIP"
	}

	getIngressYaml: ingress.#Ingress & {
		name:               uri + "-nocalhost"
		className:          "nginx"
		hostName:           domain
		path:               "/"
		"namespace":        namespace
		backendServiceName: svcName
		"ingressVersion":   ingressVersion
	}

	applyIngressYaml: kubectl.#Manifest & {
		"kubeconfig": kubeconfig
		manifest:     getIngressYaml.manifestStream
		"namespace":  namespace
		"waitFor":    waitFor
	}

	success: helmInstall.success & applyIngressYaml.success
}
