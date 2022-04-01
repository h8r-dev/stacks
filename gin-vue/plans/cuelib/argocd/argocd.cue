package argocd

import (
	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"strconv"
	"universe.dagger.io/bash"
	"github.com/h8r-dev/gin-vue/plans/cuelib/kubectl"
	"github.com/h8r-dev/gin-vue/plans/cuelib/base"
	"github.com/h8r-dev/gin-vue/plans/cuelib/h8r"
	"github.com/h8r-dev/gin-vue/plans/cuelib/ingress"
)

#Install: {
	// Kubeconfig
	kubeconfig: string | dagger.#Secret

	// Install namespace
	namespace: string

	// Manifest url
	url: string

	// Wait for

	uri:            string
	ingressVersion: string
	domain:         string
	host:           string

	// ArgoCD admin password
	install: kubectl.#Apply & {
		url:          "https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"
		"namespace":  namespace
		"kubeconfig": kubeconfig
	}

	argoIngress: ingress.#Ingress & {
		name:               uri + "-argocd"
		className:          "nginx"
		hostName:           domain
		path:               "/"
		"namespace":        namespace
		backendServiceName: "argocd-server"
		backendServicePort: 80
		"ingressVersion":   ingressVersion
	}

	deployArgoCDIngress: kubectl.#Manifest & {
		"kubeconfig": kubeconfig
		manifest:     argoIngress.manifestStream
		"namespace":  namespace
		waitFor:      install.success
	}

	createH8rIngress: h8r.#CreateH8rIngress & {
		name:     uri + "-argocd"
		"host":   host
		"domain": domain
		port:     "80"
	}

	// waitFor: deployArgoCDIngress.success & createH8rIngress.success

	patch: bash.#Run & {
		always: true
		input:  install.output
		mounts: "kubeconfig": {
			dest:     "/kubeconfig"
			contents: kubeconfig
		}
		env: {
			KUBECONFIG: "/kubeconfig"
			NAMESPACE:  namespace
		}
		script: contents: #"""
			# patch deployment cause ingress redirct: https://github.com/argoproj/argo-cd/issues/2953
			kubectl patch deployment argocd-server --patch '{"spec": {"template": {"spec": {"containers": [{"name": "argocd-server","command": ["argocd-server", "--insecure"]}]}}}}' -n $NAMESPACE
			kubectl patch statefulset argocd-application-controller --patch '{"spec": {"template": {"spec": {"containers": [{"name": "argocd-application-controller","command": ["argocd-application-controller", "--app-resync", "30"]}]}}}}' -n $NAMESPACE
			kubectl wait --for=condition=Available deployment argocd-server -n $NAMESPACE --timeout 600s
			kubectl rollout status --watch --timeout=600s statefulset/argocd-application-controller -n $NAMESPACE
			secret=$(kubectl -n $NAMESPACE get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo)
			echo $secret > /secret
			"""#
	}

	secretFile: core.#ReadFile & {
		input: patch.output.rootfs
		path:  "/secret"
	}

	content: secretFile.contents

	success: patch.success & deployArgoCDIngress.success & createH8rIngress.success
}

// ArgoCD configuration
#Config: {
	// ArgoCD CLI binary version
	version: *"v2.3.1" | string

	// ArgoCD server
	server: string

	// ArgoCD project
	project: *"default" | string

	// Basic authentication to login
	basicAuth: {
		// Username
		username: string

		// Password
		password: string
	}

	// ArgoCD authentication token
	token: *null | dagger.#Secret
}

// Re-usable CLI component
#CLI: {
	config: #Config

	_kubectlImage: base.#Kubectl

	run: bash.#Run & {
		always: true
		input:  _kubectlImage.output
		env: {
			VERSION:       config.version
			ARGO_SERVER:   config.server
			ARGO_USERNAME: config.basicAuth.username
			ARGO_PASSWORD: config.basicAuth.password
		}
		script: contents: #"""
				curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/download/$VERSION/argocd-linux-amd64 &&
				chmod +x /usr/local/bin/argocd
				# wait until server ready
				ARGO_PASSWORD=$(echo $ARGO_PASSWORD | xargs)
				echo $ARGO_SERVER'-'$ARGO_PASSWORD'-'$ARGO_USERNAME
				curl --retry 300 --retry-delay 2 $ARGO_SERVER --retry-all-errors --fail --insecure
				argocd login "$ARGO_SERVER" --username "$ARGO_USERNAME" --password "$ARGO_PASSWORD" --insecure --grpc-web
			"""#
	}

	output: run.output
}

// Create an ArgoCD application
#App: {
	// ArgoCD configuration
	config: #Config

	// App name
	name: string

	// Repository url (git or helm)
	repo: string

	// Folder to deploy
	path: "." | string

	// Destination server
	server: *"https://kubernetes.default.svc" | string

	// Destination namespace
	namespace: *"default" | string

	// Helm set values, such as "key1=value1,key2=value2"
	helmSet: string | *""

	waitFor: bool

	_cli: #CLI & {
		"config": config
	}

	run: bash.#Run & {
		input: _cli.output
		script: contents: #"""
			echo $APP_NAME'-'$APP_REPO'-'$APP_PATH'-'$APP_SERVER'-'$APP_NAMESPACE
			APP_REPO=$(echo $APP_REPO | xargs)
			setOps=""
			for i in $(echo $HELM_SET | tr "," "\n")
			do
			setOps="$setOps --helm-set "$i""
			done
			echo $setOps
			while ! argocd app create "$APP_NAME" \
				--repo "$APP_REPO" \
				--path "$APP_PATH" \
				--dest-server "$APP_SERVER" \
				--dest-namespace "$APP_NAMESPACE" \
				--sync-option CreateNamespace=true \
				--sync-policy automated \
				--grpc-web \
				--upsert \
				$setOps; 
			do 
				sleep 5
				echo 'wait for argocd project: '$APP_REPO
			done
			"""#
		always: true
		env: {
			APP_NAME:      name
			APP_REPO:      repo
			APP_PATH:      path
			APP_SERVER:    server
			APP_NAMESPACE: namespace
			HELM_SET:      helmSet
			WAIT_FOR:      strconv.FormatBool(waitFor)
		}
	}

	output: run.output
}
