package argocd

import (
	"github.com/h8r-dev/stacks/chain/internal/deploy/kubectl"
	"github.com/h8r-dev/stacks/chain/internal/cd/argocd"
	"github.com/h8r-dev/stacks/chain/internal/network/ingress"
	"universe.dagger.io/bash"
	"github.com/h8r-dev/stacks/chain/components/origin"
	"dagger.io/dagger/core"
)

#Instance: {
	input: #Input
	src:   core.#Source & {
		path: "."
	}
	// do:    kubectl.#Apply & {
	//  url:        input.url
	//  namespace:  input.namespace
	//  kubeconfig: input.kubeconfig
	//  waitFor:    input.waitFor
	// }
	do: bash.#Run & {
		always:  true
		"input": input.image
		env: {
			NAMESPACE:          input.namespace
			VERSION:            input.version
			OUTPUT_PATH:        input.helmName
			NETWORK_TYPE:       input.networkType
			CHART_URL_INTERNAL: origin.#Origin.argocd.internal.url
			CHART_URL_GLOBAL:   origin.#Origin.argocd.global.url
		}
		mounts: kubeconfig: {
			dest:     "/root/.kube/config"
			type:     "secret"
			contents: input.kubeconfig
		}
		workdir: "/tmp"
		script: {
			directory: src.output
			filename:  "create.sh"
		}
	}
	// patch argocd http
	_patch: argocd.#Patch & {
		namespace:  input.namespace
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
		hostName:           input.domain.infra.argocd
		path:               "/"
		backendServiceName: "argo-argocd-server"
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
