package main

import (
	"strings"
	"dagger.io/dagger"
	"universe.dagger.io/alpine"
	"universe.dagger.io/bash"
	"universe.dagger.io/docker"
	"github.com/h8r-dev/gin-vue/plans/cuelib/helm"
	"github.com/h8r-dev/gin-vue/plans/cuelib/ingress"
	"github.com/h8r-dev/gin-vue/plans/cuelib/kubectl"
)

// Automatically setup infra resources:
//   Nocalhost, Loki, Granfana, Prometheus, ArgoCD

#Kubectl: {
	version: string | *"v1.23.5"
	image:   docker.#Build & {
		steps: [
			alpine.#Build & {
				packages: {
					bash: {}
					curl: {}
				}
			},
			bash.#Run & {
				workdir: "/src"
				script: contents: #"""
					curl -LO https://dl.k8s.io/release/\#(version)/bin/linux/amd64/kubectl
					chmod +x kubectl
					mv kubectl /usr/local/bin/
					"""#
			},
		]
	}
}

#Helm: {
	helmversion:    string | *"3.8.1"
	kubectlversion: string | *"1.23.5"
	packages: [pkgName=string]: version: string | *""
	packages: {
		bash: {}
		curl: {}
	}
	image: docker.#Build & {
		steps: [
			docker.#Pull & {
				source: "index.docker.io/alpine/helm:\(helmversion)"
			},
			for pkgName, pkg in packages {
				docker.#Run & {
					command: {
						name: "apk"
						args: ["add", "\(pkgName)\(pkg.version)"]
						flags: {
							"-U":         true
							"--no-cache": true
						}
					}
				}
			},
			bash.#Run & {
				script: contents: #"""
					curl -LO https://dl.k8s.io/release/\#(kubectlversion)/bin/linux/amd64/kubectl
					chmod +x kubectl
					mv kubectl /usr/local/bin/
					"""#
			},
		]
	}
	output: image.output
}

#InstallChart: {
	// input values
	releasename: string
	repository:  string
	chartname:   string
	namespace:   string | *""
	kubeconfig:  dagger.#Secret

	// dependencies
	deps: #Helm

	run: bash.#Run & {
		input: deps.output
		mounts: "/etc/kubernetes/config": dagger.#Mount & {
			dest:     "/etc/kubernetes/config"
			type:     "secret"
			contents: kubeconfig
		}
		env: {
			KUBECONFIG:     "/etc/kubernetes/config"
			HELM_NAMESPACE: namespace
			TMP_REPO:       repository
			RELEASE_NAME:   releasename
			CHART_NAME:     chartname
		}
		script: contents: #"""
			helm repo add tmp-repo $TMP_REPO
			helm install $RELEASE_NAME tmp-repo/$CHART_NAME
			"""#
	}
}

#DeleteChart: {
	// input values
	releasename: string
	namespace:   string | *""
	kubeconfig:  dagger.#Secret

	// dependencies
	deps: #Helm

	run: bash.#Run & {
		input: deps.output
		mounts: "/etc/kubernetes/config": dagger.#Mount & {
			dest:     "/etc/kubernetes/config"
			type:     "secret"
			contents: kubeconfig
		}
		env: {
			KUBECONFIG:     "/etc/kubernetes/config"
			RELEASE_NAME:   releasename
			HELM_NAMESPACE: namespace
		}
		script: contents: #"""
			helm delete $RELEASE_NAME
			"""#
	}
}
