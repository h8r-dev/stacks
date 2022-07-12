package deploy

import (
	"encoding/yaml"
	"dagger.io/dagger"
	"github.com/h8r-dev/stacks/chain/v4/cd/argocd"
	"github.com/h8r-dev/stacks/chain/v4/deploy/chart"
	"github.com/h8r-dev/stacks/chain/v3/component/scm/github"         // FIXME: this is v3 pkg
	v3argocd "github.com/h8r-dev/stacks/chain/v3/component/cd/argocd" // FIXME: this is v3 pkg
)

#Init: {
	args:       _
	kubeconfig: dagger.#Secret
	cdVar:      dagger.#Secret

	_createHelmChart: {
		for s in args.application.service {
			(s.name): chart.#Create & {
				input: {
					name:     s.name
					appName:  args.application.name
					domain:   args.application.domain
					starter:  "helm-starter/go/gin"
					repoURL:  s.repo.url
					imageURL: s.image.repository
					if s.type == "backend" {
						ingressHostPath:        "/api"
						rewriteIngressHostPath: true
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
			password:     args.image.password
			"kubeconfig": kubeconfig
		}
	}

	_crateRepo: github.#Push & {
		input: {
			repositoryName:      args.application.name + "-deploy" // FIXME
			contents:            _createEncryptedSecret.output.chart
			personalAccessToken: args.scm.token
			organization:        args.scm.organization
			visibility:          "private" // FIXME
			"kubeconfig":        kubeconfig
		}
	}

	_createApp: v3argocd.#CreateApp & {
		input: {
			name:               args.application.name
			repositoryPassword: args.scm.token
			repositoryURL:      args.application.deploy.url
			appPath:            "\(name)"
			argoVar:            cdVar
			waitFor:            _crateRepo.output.success
		}
	}

	argocd.#ApplicationSet & {
		name:         args.application.name
		repo:         args.application.deploy.url
		"kubeconfig": kubeconfig
		waitFor:      _createApp.output.subcharts
	}
}
