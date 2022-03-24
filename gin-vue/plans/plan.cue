package main

import (
	"dagger.io/dagger"
	"universe.dagger.io/bash"
	"github.com/h8r-dev/gin-vue/plans/cuelib/helm"
	"github.com/h8r-dev/gin-vue/plans/cuelib/random"
)

dagger.#Plan & {
	client: {
		filesystem: code: read: contents: dagger.#FS
		commands: kubeconfig: {
			name: "cat"
			args: ["\(env.KUBECONFIG)"]
			stdout: dagger.#Secret
		}
		env: {
			KUBECONFIG:   string
			APP_NAME:     string
			ORGANIZATION: string
			GITHUB_TOKEN: dagger.#Secret
		}
		filesystem: ingress_version: write: contents: actions.getIngressVersion.export.files["/result"]
	}

	actions: {
		kubectl: #Kubectl
		uri:     random.#String

		// Get ingress version, i.e. v1 or v1beta1
		getIngressVersion: bash.#Run & {
			input:   kubectl.image.output
			workdir: "/src"
			mounts: "KubeConfig Data": {
				dest:     "/kubeconfig"
				contents: client.commands.kubeconfig.stdout
			}
			script: contents: #"""
				ingress_result=$(kubectl --kubeconfig /kubeconfig api-resources --api-group=networking.k8s.io)
				if [[ $ingress_result =~ "v1beta1" ]]; then
				 echo 'v1beta1' > /result
				else
				 echo 'v1' > /result
				fi
				"""#
			export: files: "/result": _
		}

		// Should be the chat you want to install
		installNocalhost: #InstallChart & {
			releasename: "nocalhost"
			repository:  "https://nocalhost-helm.pkg.coding.net/nocalhost/nocalhost"
			chartname:   "nocalhost"
			kubeconfig:  client.env.KUBECONFIG_DATA
		}

		testCreateH8rIngress: #CreateH8rIngress & {
			name:   "just-a-test-" + uri.output
			host:   "1.1.1.1"
			domain: uri.output + ".foo.bar"
			port:   "80"
		}

		installIngress: helm.#Chart & {
			name:       "ingress-nginx"
			repository: "https://h8r-helm.pkg.coding.net/release/helm"
			chart:      "ingress-nginx"
			namespace:  "ingress-nginx"
			action:     "installOrUpgrade"
			kubeconfig: client.commands.kubeconfig.stdout
			values:     #ingressNginxSetting
			wait:       true
		}

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

		initRepos: {
			applicationName: client.env.APP_NAME
			accessToken:     client.env.GITHUB_TOKEN
			organization:    client.env.ORGANIZATION
			sourceCodeDir:   client.filesystem.code.read.contents

			initRepo: #InitRepo & {
				sourceCodePath:    "go-gin"
				suffix:            ""
				"applicationName": applicationName
				"accessToken":     accessToken
				"organization":    organization
				"sourceCodeDir":   sourceCodeDir
			}

			initFrontendRepo: #InitRepo & {
				suffix:            "-front"
				sourceCodePath:    "vue-front"
				"applicationName": applicationName
				"accessToken":     accessToken
				"organization":    organization
				"sourceCodeDir":   sourceCodeDir
			}

			initHelmRepo: #InitRepo & {
				suffix:            "-deploy"
				sourceCodePath:    "helm"
				isHelmChart:       "true"
				"applicationName": applicationName
				"accessToken":     accessToken
				"organization":    organization
				"sourceCodeDir":   sourceCodeDir
			}
		}

		deleteNocalhost: #DeleteChart & {
			releasename: "nocalhost"
			kubeconfig:  client.env.KUBECONFIG_DATA
		}

		deleteRepos: {
			applicationName: client.env.APP_NAME
			accessToken:     client.env.GITHUB_TOKEN
			organization:    client.env.ORGANIZATION

			DeleteRepo: #DeleteRepo & {
				reponame:       "\(applicationName)"
				githubtoken:    accessToken
				"organization": organization
			}
			DeleteFrontendRepo: #DeleteRepo & {
				reponame:       "\(applicationName)-front"
				githubtoken:    accessToken
				"organization": organization
			}
			DeleteHelmRepo: #DeleteRepo & {
				reponame:       "\(applicationName)-deploy"
				githubtoken:    accessToken
				"organization": organization
			}
		}
	}
}
