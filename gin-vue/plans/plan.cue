package main

import (
	"dagger.io/dagger"
	"github.com/h8r-dev/gin-vue/plans/cuelib/helm"
	"github.com/h8r-dev/gin-vue/plans/cuelib/ingress"
	"github.com/h8r-dev/gin-vue/plans/cuelib/grafana"
	"github.com/h8r-dev/gin-vue/plans/cuelib/argocd"
	"github.com/h8r-dev/gin-vue/plans/cuelib/kubectl"
	"github.com/h8r-dev/gin-vue/plans/cuelib/prometheus"
	"github.com/h8r-dev/gin-vue/plans/cuelib/h8r"
)

dagger.#Plan & {
	client: {
		filesystem: {
			code: read: contents: dagger.#FS
			"./output.yaml": write: {
				// Convert a CUE value into a YAML formatted string
				contents: actions.up.outputYaml.output
			}
		}
		//filesystem: code: read: contents: dagger.#FS
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
		// filesystem: "config.yaml": write: {
		//  // Convert a CUE value into a YAML formatted string
		//  contents: yaml.Marshal(actions.outputStruct)
		// }
		//filesystem: ingress_version: write: contents: actions.getIngressVersion.export.files["/result"]
	}

	actions: {
		// get ingress endpoint
		up: {
			applicationInstallNamespace: client.env.APP_NAME + "-" + appInstallNamespace

			getIngressEndPoint: ingress.#GetIngressEndpoint & {
				kubeconfig: client.commands.kubeconfig.stdout
			}

			// get ingress version
			getIngressVersion: ingress.#GetIngressVersion & {
				kubeconfig: client.commands.kubeconfig.stdout
			}

			// installNocalhost: #InstallNocalhost & {
			//  "uri":          "just-test" + uri.output
			//  kubeconfig:     client.commands.kubeconfig.stdout
			//  ingressVersion: getIngressVersion.content
			//  domain:         uri.output + ".nocalhost" + infraDomain
			//  host:           getIngressEndPoint.endPoint
			//  namespace:      "nocalhost"
			//  name:           "nocalhost"
			// }

			// testCreateH8rIngress: #CreateH8rIngress & {
			//  name:   "just-a-test-" + uri.output
			//  host:   "1.1.1.1"
			//  domain: uri.output + ".foo.bar"
			//  port:   "80"
			// }

			installIngress: helm.#Chart & {
				name:       "ingress-nginx"
				repository: "https://h8r-helm.pkg.coding.net/release/helm"
				chart:      "ingress-nginx"
				namespace:  "ingress-nginx"
				action:     "installOrUpgrade"
				kubeconfig: client.commands.kubeconfig.stdout
				values:     ingressNginxSetting
				wait:       true
			}

			// // upgrade ingress nginx for serviceMonitor
			// // should wait for installIngress and installPrometheusStack
			upgradeIngress: helm.#Chart & {
				name:       "ingress-nginx"
				repository: "https://h8r-helm.pkg.coding.net/release/helm"
				chart:      "ingress-nginx"
				namespace:  "ingress-nginx"
				action:     "installOrUpgrade"
				kubeconfig: client.commands.kubeconfig.stdout
				values:     ingressNginxUpgradeSetting
				wait:       true
				waitFor:    installIngress.success & installPrometheusLokiStack.success
			}

			// install argocd
			installArgoCD: argocd.#Install & {
				kubeconfig:     client.commands.kubeconfig.stdout
				namespace:      argoCDNamespace
				url:            "https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"
				"uri":          uri.output
				ingressVersion: getIngressVersion.content
				domain:         argocdDomain
				host:           getIngressEndPoint.content
			}

			createApp: argocd.#App & {
				waitFor: installArgoCD.success
				config:  argocd.#Config & {
					version: "v2.3.1"
					server:  argocdDomain
					basicAuth: {
						username: argoCDDefaultUsername
						password: installArgoCD.content
					}
				}
				name:      client.env.APP_NAME
				repo:      initRepos.initHelmRepo.url
				namespace: applicationInstallNamespace
				path:      "."
				helmSet:   "ingress.hosts[0].host=" + appDomain + ",ingress.hosts[0].paths[0].path=/,ingress.hosts[0].paths[0].pathType=ImplementationSpecific"
			}

			// create image pull secret for argocd
			createImagePullSecret: kubectl.#CreateImagePullSecret & {
				kubeconfig: client.commands.kubeconfig.stdout
				username:   client.env.ORGANIZATION
				password:   client.env.GITHUB_TOKEN
				namespace:  applicationInstallNamespace
			}

			// install prometheus and loki stack
			installPrometheusLokiStack: {
				installPrometheus: prometheus.#installPrometheusStack & {
					"uri":                uri.output
					kubeconfig:           client.commands.kubeconfig.stdout
					ingressVersion:       getIngressVersion.content
					"prometheusDomain":   prometheusDomain
					"grafanaDomain":      grafanaDomain
					"alertmanagerDomain": alertmanagerDomain
					host:                 getIngressEndPoint.content
					name:                 prometheusReleaseName
					namespace:            prometheusNamespace
					waitFor:              installIngress.success
				}

				installLoki: prometheus.#installLokiStack & {
					namespace:  lokiNamespace
					kubeconfig: client.commands.kubeconfig.stdout
				}

				getGrafanaSecret: grafana.#GetGrafanaSecret & {
					kubeconfig: client.commands.kubeconfig.stdout
					secretName: prometheusReleaseName + "-grafana"
					namespace:  prometheusNamespace
				}

				initIngressNginxDashboard: grafana.#CreateIngressDashboard & {
					url:      grafanaDomain
					username: grafanaDefaultUsername
					password: getGrafanaSecret.secret
					waitFor:  installPrometheus.success
				}

				initLokiDataSource: grafana.#CreateLokiDataSource & {
					url:      grafanaDomain
					username: "admin"
					password: getGrafanaSecret.secret
					waitFor:  installPrometheus.success & installLoki.success
				}

				success: installPrometheus.success & installLoki.success
			}

			initApplication: app: h8r.#CreateH8rIngress & {
				name:   uri.output + "-gin-vue"
				host:   getIngressEndPoint.content
				domain: applicationInstallNamespace + "." + appDomain
				port:   "80"
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

			// output cue struct
			outputYaml: #OutputStruct & {
				application: {
					domain:  applicationInstallNamespace + "." + appDomain
					ingress: getIngressEndPoint.content
				}
				repository: {
					frontend: initRepos.initFrontendRepo.url
					backend:  initRepos.initRepo.url
					deploy:   initRepos.initHelmRepo.url
				}
				prometheus: domain: prometheusDomain
				grafana: {
					domain:   grafanaDomain
					username: grafanaDefaultUsername
					password: installPrometheusLokiStack.getGrafanaSecret.secret
				}
				alertManager: domain: alertmanagerDomain
				argocd: {
					domain:   argocdDomain
					username: argoCDDefaultUsername
					password: installArgoCD.content
				}
				nocalhost: {
					domain:   nocalhostDomain
					username: nocalhostDefaultUsername
					password: nocalhostDefaultPassword
				}
			}
		}

		deleteRepos: {
			applicationName: client.env.APP_NAME
			accessToken:     client.env.GITHUB_TOKEN
			organization:    client.env.ORGANIZATION

			deleteRepo: #DeleteRepo & {
				suffix:            ""
				"applicationName": applicationName
				"accessToken":     accessToken
				"organization":    organization
			}

			deleteFrontendRepo: #DeleteRepo & {
				suffix:            "-front"
				"applicationName": applicationName
				"accessToken":     accessToken
				"organization":    organization
			}

			deleteHelmRepo: #DeleteRepo & {
				suffix:            "-deploy"
				"applicationName": applicationName
				"accessToken":     accessToken
				"organization":    organization
			}
		}

		deleteNocalhost: #DeleteChart & {
			releasename: "nocalhost"
			kubeconfig:  client.env.KUBECONFIG_DATA
		}
	}
}
