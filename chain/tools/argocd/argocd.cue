package argocd

import (
	"github.com/h8r-dev/stacks/cuelib/deploy/kubectl"
	"github.com/h8r-dev/stacks/cuelib/cd/argocd"
	"github.com/h8r-dev/stacks/cuelib/network/ingress"
	"universe.dagger.io/bash"
	"github.com/h8r-dev/chain/supply/base"
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
		bash.#Run & {
			env: {
				ARGO_SERVER:   base.#DefaultInternalDomain.infra.argocd
				ARGO_USERNAME: "admin"
				if input.set != null {
					HELM_SET: input.set
				}
				APP_NAMESPACE: base.#DefaultDomain.application.productionNamespace
				APP_SERVER:    "https://kubernetes.default.svc"
			}
			"input": input.image
			workdir: "/scaffold"
			script: contents: #"""
					cat /infra/argocd/secret
					deployRepoPath=$(cat /h8r/application)
					cd /scaffold/$deployRepoPath
					ls

					# Helm sets
					setOps=""
					if [[ $HELM_SET ]]; then
						echo 'helm values set'
						for i in $(echo $HELM_SET | tr "," "\n")
						do
							setOps="$setOps --helm-set "$i""
						done
					fi
					repoURL=$(git config --get remote.origin.url | tr -d '\n')
					# wait until argocd is ready
					curl --retry 300 --retry-delay 2 $ARGO_SERVER --fail --insecure >> /dev/null 2>&1  
					echo 'y' | argocd login "$ARGO_SERVER" --username "$ARGO_USERNAME" --password "$(cat /infra/argocd/secret)" --insecure --grpc-web
					
					# Add argocd repo
					argocd repo add $repoURL --username $(cat /scm/github/organization) --password $(cat /scm/github/pat)

					# Create business application for ArgoCD
					# look for directory, ignore files
					for file in */ ;
					do
						APP_NAME=$(echo $file | tr -d '/')
						if [ $APP_NAME == "infra" ]; then
							continue
						fi
						while ! argocd app create "$APP_NAME" \
							--repo "$repoURL" \
							--path "$file" \
							--dest-server "$APP_SERVER" \
							--dest-namespace "$deployRepoPath-$APP_NAMESPACE" \
							--sync-option CreateNamespace=true \
							--sync-policy automated \
							--grpc-web \
							--insecure \
							--plaintext \
							--upsert \
							$setOps;
						do 
							sleep 5
							echo 'wait for argocd project: '$APP_NAME
						done
					done

					# Create infra application for ArgoCD
					cd ./infra
					for file in */ ;
					do
						APP_NAME=$(echo $file | tr -d '/')
						while ! argocd app create "$APP_NAME" \
							--repo "$repoURL" \
							--path "infra/$APP_NAME" \
							--dest-server "$APP_SERVER" \
							--dest-namespace "$APP_NAME" \
							--sync-option CreateNamespace=true \
							--sync-policy automated \
							--grpc-web \
							--insecure \
							--plaintext \
							--upsert \
							$setOps;
						do
							sleep 5
							echo 'wait for argocd project: '$APP_NAME
						done
					done
				"""#
		}
	}
	output: #Output & {
		image:   do.output
		success: do.success
	}
}
