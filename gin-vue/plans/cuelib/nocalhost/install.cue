package nocalhost

import (
	"strings"
	"dagger.io/dagger"
	"github.com/h8r-dev/cuelib/helm"
	"github.com/h8r-dev/cuelib/kubectl"
	"github.com/h8r-dev/cuelib/ingress"
	"github.com/h8r-dev/cuelib/h8r"
)

// install nocalhost
#Install: {
	uri:            string
	kubeconfig:     string | dagger.#Secret
	ingressVersion: string
	domain:         string
	// ingress ip
	host:      string
	name:      string
	namespace: string
	waitFor:   bool

	helmInstall: helm.#Chart & {
		"name":       name
		repository:   "https://nocalhost.github.io/charts"
		chart:        "nocalhost"
		"namespace":  namespace
		"kubeconfig": kubeconfig
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
		"host":   strings.Replace(host, "\n", "", -1)
		"domain": strings.Replace(domain, "\n", "", -1)
		port:     "80"
	}

	success: helmInstall.success & createH8rIngress.success & applyIngressYaml.success
}
