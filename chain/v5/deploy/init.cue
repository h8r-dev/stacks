package deploy

import (
	"encoding/yaml"
	"dagger.io/dagger"
	"github.com/h8r-dev/stacks/chain/v5/deploy/chart"
	"github.com/h8r-dev/stacks/chain/v5/pkg/k8s/kubectl"
	"github.com/h8r-dev/stacks/chain/v5/crd/forkmain"
	"github.com/h8r-dev/stacks/chain/v3/component/scm/github" // FIXME: this is v3 pkg
	"github.com/h8r-dev/stacks/chain/v5/cd/argocd"
)

#Init: {
	args:       _
	kubeconfig: dagger.#Secret
	cdVar:      dagger.#Secret
	middlewareCharts: [...dagger.#FS]

	_createHelmChart: {
		for s in args.application.service {
			(s.name): chart.#Create & {
				input: {
					name:    s.name
					appName: args.application.name
					if s.framework == "gin" {
						starter: "helm-starter/go/gin"
					}
					if s.framework == "nextjs" {
						starter: "helm-starter/nodejs/nextjs"
					}
					if s.framework == "spring-boot" {
						starter: "helm-starter/java/spring-boot"
					}
					if s.framework == "vuejs" {
						starter: "helm-starter/static/vuejs"
					}
					set:      """
						'.fullnameOverride = "\(s.name)"'
						"""
					repoURL:  s.repo.url
					imageURL: s.image.repository
					if len(s.setting.expose) > 0 {
						_expose:  s.setting.expose[0]
						_ingress: chart.#Ingress & {
							input: {
								rewrite: _expose.rewrite
								host:    args.application.domain
								paths:   _expose.paths
							}
						}
						ingressValue: yaml.Marshal(_ingress.info)
						port:         "\(_expose.port)"
					}
					deploymentEnv: yaml.Marshal(s.setting.env)
				}
			}
		}
	}

	_subChartList: [
		for s in args.application.service {
			_createHelmChart[(s.name)].output.chart
		},
		for m in middlewareCharts {
			m
		},
	]

	_createParentChart: {
		chart.#CreateParent & {
			input: {
				name:      args.application.name
				subcharts: _subChartList
			}
		}
	}

	_createEncryptedSecret: chart.#EncryptSecret & {
		input: {
			name:         args.application.name
			chart:        _createParentChart.output.chart
			username:     args.image.username
			password:     args.internal.imagePassword
			"kubeconfig": kubeconfig
		}
	}

	_createRepo: github.#Push & {
		input: {
			repositoryName:      args.application.name + "-deploy" // FIXME
			contents:            _createEncryptedSecret.output.chart
			personalAccessToken: args.internal.githubToken
			organization:        args.scm.organization
			visibility:          "private" // FIXME
			"kubeconfig":        kubeconfig
		}
	}

	_serRepoAuth: argocd.#SetRepoAuth & {
		input: {
			argoVar:            cdVar
			repositoryURL:      args.application.deploy.url
			repositoryPassword: args.internal.githubToken
			waitFor:            _createRepo.output.success
		}
	}

	_createApp: kubectl.#Apply & {
		_app: argocd.#ApplicationCRD & {
			input: {
				appName:   args.application.name
				chartUrl:  args.application.deploy.url
				envPath:   args.application.deploy.valuesFile
				namespace: args.application.namespace
			}
		}
		_contents: yaml.Marshal(_app.CRD)
		input: {
			"kubeconfig": kubeconfig
			contents:     _contents
			waitFor:      _serRepoAuth.output.success
		}
	}

	_crd: {
		_application: kubectl.#Apply & {
			_app: forkmain.#Application & {
				input: {
					name:    args.application.name
					appName: args.application.name
				}
			}
			_contents: yaml.Marshal(_app.CRD)
			input: {
				"kubeconfig": kubeconfig
				contents:     _contents
				waitFor:      _createApp.output.success
			}
		}
		_environment: kubectl.#Apply & {
			_env: forkmain.#Environment & {
				input: {
					name:         args.application.name + "-main"
					envName:      args.application.name + "-main"
					appName:      args.application.name
					chartURL:     args.application.deploy.url
					chartPath:    args.application.name
					envAccessURL: args.application.domain
					envNamespace: args.application.namespace
				}
			}
			_contents: yaml.Marshal(_env.CRD)
			input: {
				"kubeconfig": kubeconfig
				contents:     _contents
				waitFor:      _createApp.output.success
			}
		}
		_repo: {
			for s in args.application.service {
				(s.name): kubectl.#Apply & {
					_env: forkmain.#Repository & {
						input: {
							name:         args.application.name + "-" + s.name
							appName:      args.application.name
							repoName:     s.name
							repoURL:      s.repo.url
							organization: args.scm.organization
						}
					}
					_contents: yaml.Marshal(_env.CRD)
					input: {
						"kubeconfig": kubeconfig
						contents:     _contents
						waitFor:      _createApp.output.success
					}
				}
			}
		}
	}
}
