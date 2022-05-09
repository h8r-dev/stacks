package argocd

import (
	"github.com/h8r-dev/stacks/chain/internal/deploy/kubectl"
	"github.com/h8r-dev/stacks/chain/internal/cd/argocd"
	"github.com/h8r-dev/stacks/chain/internal/network/ingress"
	"universe.dagger.io/bash"
	"dagger.io/dagger/core"
	"github.com/h8r-dev/stacks/chain/factory/basefactory"
)

#Instance: {
	input: #Input
	do:    kubectl.#Apply & {
		url:        input.url
		namespace:  input.namespace
		kubeconfig: input.kubeconfig
		waitFor:    input.waitFor
	}
	// patch argocd http
	_patch: argocd.#Patch & {
		kubeconfig: input.kubeconfig
		"input":    input.image
		waitFor:    do.success
	}
	// set ingress for argocd
	ingressVersion: ingress.#GetIngressVersion & {
		image:      input.image
		kubeconfig: input.kubeconfig
	}
	ingressYaml: ingress.#Ingress & {
		name:               "argocd"
		namespace:          input.namespace
		hostName:           input.domain
		path:               "/"
		backendServiceName: "argocd-server"
		"ingressVersion":   ingressVersion.content
	}
	applyIngressYaml: kubectl.#Manifest & {
		kubeconfig: input.kubeconfig
		manifest:   ingressYaml.manifestStream
		namespace:  input.namespace
	}
	output: #Output & {
		image:   _patch.output
		success: _patch.success
	}
}

#Init: {
	input: #Input
	do: {
		src: core.#Source & {
			path: "."
		}
		createApps: bash.#Run & {
			env: {
				KUBECONFIG:    "/etc/kubernetes/config"
				ARGO_SERVER:   basefactory.#DefaultInternalDomain.infra.argocd
				ARGO_URL:      basefactory.#DefaultDomain.infra.argocd
				ARGO_USERNAME: "admin"
				if input.set != null {
					HELM_SET: input.set
				}
				APP_NAMESPACE: basefactory.#DefaultDomain.application.productionNamespace
				APP_SERVER:    "https://kubernetes.default.svc"
			}
			mounts: "kubeconfig": {
				dest:     "/etc/kubernetes/config"
				contents: input.kubeconfig
			}
			"input": input.image
			workdir: "/scaffold"
			script: {
				directory: src.output
				filename:  "create-apps.sh"
			}
		}
	}
	output: #Output & {
		image:   do.createApps.output
		success: do.createApps.success
	}
}
