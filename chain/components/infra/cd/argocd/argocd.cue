package argocd

import (
	"dagger.io/dagger"
	"github.com/h8r-dev/stacks/chain/internal/deploy/kubectl"
	"github.com/h8r-dev/stacks/chain/internal/network/ingress"
	"universe.dagger.io/bash"
	"github.com/h8r-dev/stacks/chain/components/origin"
	"dagger.io/dagger/core"
	"universe.dagger.io/docker"
	"strconv"
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
	_patch: #Patch & {
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

#Patch: {
	kubeconfig: dagger.#Secret
	input:      docker.#Image
	namespace:  string | *"argocd"
	waitFor:    bool
	do:         bash.#Run & {
		always:  true
		"input": input
		mounts: "kubeconfig": {
			dest:     "/kubeconfig"
			contents: kubeconfig
		}
		env: {
			KUBECONFIG: "/kubeconfig"
			NAMESPACE:  namespace
			WAIT_FOR:   strconv.FormatBool(waitFor)
		}
		script: contents: #"""
			# patch deployment cause ingress redirct: https://github.com/argoproj/argo-cd/issues/2953
			kubectl patch deployment argo-argocd-server --patch '{"spec": {"template": {"spec": {"containers": [{"name": "server","command": ["argocd-server", "--insecure"]}]}}}}' -n $NAMESPACE
			kubectl patch statefulset argo-argocd-application-controller --patch '{"spec": {"template": {"spec": {"containers": [{"name": "application-controller","command": ["argocd-application-controller", "--app-resync", "30"]}]}}}}' -n $NAMESPACE
			kubectl wait --for=condition=Available deployment argo-argocd-server -n $NAMESPACE --timeout 600s
			kubectl rollout status --watch --timeout=600s statefulset/argo-argocd-application-controller -n $NAMESPACE
			kubectl rollout status --watch --timeout=600s deployment/argo-argocd-server -n $NAMESPACE
			secret="$(kubectl -n $NAMESPACE get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo)"
			mkdir -p /infra/argocd
			printf -- $secret > /infra/argocd/secret
			"""#
		export: files: "/infra/argocd/secret": string
	}
	output:  do.output
	secret:  do.export.files."/infra/argocd/secret"
	success: do.success
}
