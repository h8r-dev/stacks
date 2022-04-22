package certmanager

import (
	"github.com/h8r-dev/stacks/cuelib/deploy/helm"
	"universe.dagger.io/bash"
	"universe.dagger.io/docker"
	"dagger.io/dagger"
	"github.com/h8r-dev/stacks/cuelib/deploy/kubectl"
	"encoding/json"
	"strconv"

)

#InstallCertManager: {
	kubeconfig: dagger.#Secret

	install: helm.#Chart & {
		name:         "cert-manager"
		repository:   "https://charts.jetstack.io"
		chart:        "cert-manager"
		namespace:    "cert-manager"
		set:          "installCRDs=false"
		chartVersion: "v1.8.0"
		"kubeconfig": kubeconfig
	}

	base: docker.#Pull & {
		source: "index.docker.io/alpine/k8s:1.22.6"
	}

	installCrd: bash.#Run & {
		input: base.output
		mounts: "kubeconfig": {
			dest:     "/root/.kube/config"
			contents: kubeconfig
		}
		script: contents: "kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/" + install.chartVersion + "/cert-manager.crds.yaml"
	}
	// Wait for all pods to be ready before marking the release as successful
	waitFor: bool | *true
	success: install.success & installCrd.success
}

// ACME Issuer challenged by cloudflare dns
#ACMEIssuer: {
	kubeconfig: dagger.#Secret
	name:       string | *"heighliner.dev"
	email:      string
	apiToken:   dagger.#Secret
	namespace:  "cert-manager"

	base: docker.#Pull & {
		source: "index.docker.io/alpine/k8s:1.22.6"
	}

	setSecret: bash.#Run & {
		input:   base.output
		workdir: "/root"
		env: {
			API_TOKEN: apiToken
			WAIT_FOR:  strconv.FormatBool(waitFor)
		}
		mounts: "kubeconfig": {
			dest:     "/root/.kube/config"
			contents: kubeconfig
		}
		always: true
		script: contents: "kubectl --namespace cert-manager create secret generic cloudflare-api-token --from-literal=token=$API_TOKEN --dry-run=client -o yaml | kubectl apply -f -"
	}

	issuerManifest: {
		apiVersion: "cert-manager.io/v1"
		kind:       "ClusterIssuer"
		metadata: {
			"name":      name
			"namespace": namespace
		}
		spec: acme: {
			"email": email
			server:  "https://acme-v02.api.letsencrypt.org/directory"
			privateKeySecretRef: "name": name + "-private-key"
			solvers: [
				{
					dns01: cloudflare: {
						"email": email
						apiTokenSecretRef: {
							name: "cloudflare-api-token"
							key:  "token"
						}
					}
				},
			]
		}
	}

	manifest: kubectl.#Manifest & {
		manifest:     json.Marshal(issuerManifest)
		"namespace":  namespace
		"kubeconfig": kubeconfig
		"waitFor":    waitFor
	}
	// Wait for all pods to be ready before marking the release as successful
	waitFor: bool | *true

	success: manifest.success
}

// ACME Cert
#ACMECert: {

	kubeconfig: dagger.#Secret
	namespace:  string
	name:       string
	issuer:     string | *"heighliner.dev"
	commonName: string
	domains: [...string]

	cert: {
		apiVersion: "cert-manager.io/v1"
		kind:       "Certificate"
		metadata: {
			"name":      name
			"namespace": namespace
		}
		spec: {
			secretName: name + "-secret"
			issuerRef: {
				name: issuer
				kind: "ClusterIssuer"
			}
			"commonName": commonName
			dnsNames:     domains
		}
	}

	manifest: kubectl.#Manifest & {
		manifest:     json.Marshal(cert)
		"namespace":  namespace
		"kubeconfig": kubeconfig
		"waitFor":    waitFor
	}
	// Wait for all pods to be ready before marking the release as successful
	waitFor: bool | *true

	output: manifest.success
}
