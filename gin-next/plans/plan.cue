package main

import (
	"dagger.io/dagger"
	"github.com/h8r-dev/cuelib/deploy/helm"
	"github.com/h8r-dev/cuelib/network/ingress"
	"github.com/h8r-dev/cuelib/monitoring/grafana"
	"github.com/h8r-dev/cuelib/cd/argocd"
	"github.com/h8r-dev/cuelib/deploy/kubectl"
	"github.com/h8r-dev/cuelib/monitoring/prometheus"
	"github.com/h8r-dev/cuelib/h8r/h8r"
	"github.com/h8r-dev/cuelib/dev/nocalhost"
	"github.com/h8r-dev/cuelib/scm/github"
	"github.com/h8r-dev/cuelib/framework/react/next"
	githubAction "github.com/h8r-dev/cuelib/ci/github"
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

			installIngress: helm.#Chart & {
				name:         "ingress-nginx"
				repository:   "https://kubernetes.github.io/ingress-nginx"
				chart:        "ingress-nginx"
				namespace:    "ingress-nginx"
				action:       "installOrUpgrade"
				kubeconfig:   client.commands.kubeconfig.stdout
				values:       ingressNginxSetting
				wait:         true
				chartVersion: "4.0.19"
			}

			installNocalhost: {
				install: nocalhost.#Install & {
					"uri":          uri.output
					kubeconfig:     client.commands.kubeconfig.stdout
					ingressVersion: getIngressVersion.content
					domain:         nocalhostDomain
					host:           getIngressEndPoint.content
					namespace:      "nocalhost"
					name:           "nocalhost"
					waitFor:        installIngress.success
					chartVersion:   "0.6.16"
				}

				init: nocalhost.#InitData & {
					url:                nocalhostDomain
					githubAccessToken:  client.env.GITHUB_TOKEN
					githubOrganization: client.env.ORGANIZATION
					kubeconfig:         client.commands.kubeconfig.stdout
					appName:            client.env.APP_NAME
					appGitURL:          initRepos.initHelmRepo.url
					waitFor:            install.success
				}
			}

			// upgrade ingress nginx for serviceMonitor
			// should wait for installIngress and installPrometheusStack
			upgradeIngress: helm.#Chart & {
				name:         "ingress-nginx"
				repository:   "https://kubernetes.github.io/ingress-nginx"
				chart:        "ingress-nginx"
				namespace:    "ingress-nginx"
				action:       "installOrUpgrade"
				kubeconfig:   client.commands.kubeconfig.stdout
				values:       ingressNginxUpgradeSetting
				wait:         true
				waitFor:      installIngress.success & installPrometheusLokiStack.success
				chartVersion: "4.0.19"
			}

			// install argocd
			installArgoCD: argocd.#Install & {
				kubeconfig:     client.commands.kubeconfig.stdout
				namespace:      argoCDNamespace
				url:            "https://raw.githubusercontent.com/argoproj/argo-cd/v2.3.3/manifests/install.yaml"
				"uri":          uri.output
				ingressVersion: getIngressVersion.content
				domain:         argocdDomain
				host:           getIngressEndPoint.content
				waitFor:        installIngress.success
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
				helmSet:   "ingress.hosts[0].paths[0].servicePort=80,ingress.hosts[0].paths[1].servicePort=8000,ingress.hosts[0].paths[0].path=/,ingress.hosts[0].paths[1].path=/api,ingress.hosts[0].host=" + appDomain + ",ingress.hosts[0].paths[0].serviceName=" + client.env.APP_NAME + "-front,ingress.hosts[0].paths[1].serviceName=" + client.env.APP_NAME
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
				installPrometheus: prometheus.#InstallPrometheusStack & {
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
					chartVersion:         "34.9.0"
				}

				installLoki: prometheus.#installLokiStack & {
					namespace:    lokiNamespace
					kubeconfig:   client.commands.kubeconfig.stdout
					chartVersion: "2.6.2"
				}

				getGrafanaSecret: grafana.#GetGrafanaSecret & {
					kubeconfig: client.commands.kubeconfig.stdout
					secretName: prometheusReleaseName + "-grafana"
					namespace:  prometheusNamespace
					waitFor:    installPrometheus.success
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

				//framework: "next"
				// frontend framework next
				frontend: next.#Create & {
					name:       applicationName
					typescript: true
				}
				// add github action
				addGithubAction: githubAction.#Create & {
					input: frontend.output
					path:  applicationName + "/.github/workflows"
				}

				initFrontendRepo: github.#InitRepo & {
					suffix:            "-front"
					sourceCodePath:    "root/" + applicationName
					"applicationName": applicationName
					"accessToken":     accessToken
					"organization":    organization
					sourceCodeDir:     addGithubAction.output.rootfs
				}

				initRepo: github.#InitRepo & {
					sourceCodePath:    "go-gin"
					suffix:            ""
					"applicationName": applicationName
					"accessToken":     accessToken
					"organization":    organization
					"sourceCodeDir":   sourceCodeDir
				}

				initHelmRepo: github.#InitRepo & {
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

			deleteRepo: github.#DeleteRepo & {
				suffix:            ""
				"applicationName": applicationName
				"accessToken":     accessToken
				"organization":    organization
			}

			deleteFrontendRepo: github.#DeleteRepo & {
				suffix:            "-front"
				"applicationName": applicationName
				"accessToken":     accessToken
				"organization":    organization
			}

			deleteHelmRepo: github.#DeleteRepo & {
				suffix:            "-deploy"
				"applicationName": applicationName
				"accessToken":     accessToken
				"organization":    organization
			}
		}

		deleteNocalhost: github.#DeleteChart & {
			releasename: "nocalhost"
			kubeconfig:  client.env.KUBECONFIG_DATA
		}
	}
}
