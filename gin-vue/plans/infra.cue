package main

import (
	"dagger.io/dagger"
	"universe.dagger.io/alpine"
	"universe.dagger.io/bash"
	"universe.dagger.io/docker"
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

// craete ingress by h8s server
#CreateH8rIngress: {
	// Ingress name
	name:             string
	host:             string
	domain:           string
	port:             string | *"80"
	h8rServerAddress: string | *"api.stack.h8r.io/api/v1/cluster/ingress"

	baseImage: alpine.#Build & {
		packages: {
			bash: {}
			curl: {}
		}
	}

	create: bash.#Run & {
		input: baseImage.output
		script: contents: #"""
			sh_c='sh -c'
			data_raw='{"name":"\#(name)","host":"\#(host)","domain":"\#(domain)","port":"\#(port)"}'
			do_create="curl -sw '\n%{http_code}' --retry 3 --retry-delay 2 --insecure -X POST --header 'Content-Type: application/json' --data-raw '$data_raw' \#(h8rServerAddress)"
			messages="$($sh_c "$do_create")"
			http_code=$(echo "$messages" |  tail -1)
			if [ "$http_code" -ne "200" ]; then
				#// echo error messages
				echo "$messages"
				exit 1
			fi
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

		// upgrade ingress nginx for serviceMonitor
		// should wait for installIngress and installPrometheusStack
		upgradeIngress: helm.#Chart & {
			name:       "ingress-nginx"
			repository: "https://h8r-helm.pkg.coding.net/release/helm"
			chart:      "ingress-nginx"
			namespace:  "ingress-nginx"
			action:     "installOrUpgrade"
			kubeconfig: client.commands.kubeconfig.stdout
			values:     #ingressNginxUpgradeSetting
			wait:       true
		}

		installLokiStack: helm.#Chart & {
			name:       "loki"
			repository: "https://grafana.github.io/helm-charts"
			chart:      "loki-stack"
			action:     "installOrUpgrade"
			namespace:  lokiNamespace
			kubeconfig: client.commands.kubeconfig.stdout
			wait:       true
		}

		installPrometheusStack: {
			releaseName:    "prometheus"
			kubePrometheus: helm.#Chart & {
				name:       installPrometheusStack.releaseName
				repository: "https://prometheus-community.github.io/helm-charts"
				chart:      "kube-prometheus-stack"
				action:     "installOrUpgrade"
				namespace:  prometheusNamespace
				kubeconfig: client.commands.kubeconfig.stdout
				wait:       true
			}
		}
	}
}
