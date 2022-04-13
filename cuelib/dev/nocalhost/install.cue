package nocalhost

import (
	"dagger.io/dagger"
	"github.com/h8r-dev/cuelib/network/ingress"
	"github.com/h8r-dev/cuelib/deploy/helm"
	"github.com/h8r-dev/cuelib/deploy/kubectl"
	"github.com/h8r-dev/cuelib/h8r/h8r"
)

// install nocalhost
#Install: {
	uri:            string
	kubeconfig:     string | dagger.#Secret
	ingressVersion: string
	domain:         string
	// ingress ip
	host:         string
	name:         string
	namespace:    string
	waitFor:      bool
	chartVersion: string

	helmInstall: helm.#Chart & {
		"name":         name
		repository:     "https://nocalhost.github.io/charts"
		chart:          "nocalhost"
		"namespace":    namespace
		"kubeconfig":   kubeconfig
		"chartVersion": chartVersion
	}

	getIngressYaml: ingress.#Ingress & {
		name:               uri + "-nocalhost"
		className:          "nginx"
		hostName:           domain
		path:               "/"
		"namespace":        namespace
		backendServiceName: "nocalhost-web"
		"ingressVersion":   ingressVersion
	}

	applyIngressYaml: kubectl.#Manifest & {
		"kubeconfig": kubeconfig
		manifest:     getIngressYaml.manifestStream
		"namespace":  namespace
		"waitFor":    waitFor
	}

	createH8rIngress: h8r.#CreateH8rIngress & {
		name:     uri + "-nocalhost"
		"host":   host
		"domain": domain
		port:     "80"
	}

	success: helmInstall.success & createH8rIngress.success & applyIngressYaml.success
}
