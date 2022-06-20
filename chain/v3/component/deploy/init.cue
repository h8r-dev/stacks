package deploy

import (
	"dagger.io/dagger"

	"github.com/h8r-dev/stacks/chain/v3/component/cd/argocd"
	"github.com/h8r-dev/stacks/chain/v3/component/scm/github"
	"github.com/h8r-dev/stacks/chain/v3/component/deploy/helm"
	"github.com/h8r-dev/stacks/chain/v3/internal/base"
	"github.com/h8r-dev/stacks/chain/v3/internal/var"
	"github.com/h8r-dev/stacks/chain/v3/internal/state"
)

#Init: {
	input: {
		name:           string
		domain:         string
		repoVisibility: string
		organization:   string
		waitFor:        bool | *true
		githubToken:    dagger.#Secret
		kubeconfig:     dagger.#Secret
		vars:           var.#Generator
		cdVar:          dagger.#Secret
		frameworks: [...]
	}

	_args: input

	_createHelmChart: {
		for f in _args.frameworks {
			(f.name): helm.#CreateChart & {
				input: {
					name:     _args.vars[(f.name)].repoName
					appName:  _args.name
					domain:   _args.domain
					starter:  base.HelmStarter[(f.name)]
					repoURL:  _args.vars[(f.name)].repoURL
					imageURL: _args.vars[(f.name)].imageURL
					if _args.vars[(f.name)].frameworkType == "backend" {
						ingressHostPath:        "/api"
						rewriteIngressHostPath: true
					}
				}
			}
		}
	}

	_subChartList: [ for f in _args.frameworks {
		_createHelmChart[(f.name)].output.chart
	}]

	_createParentChart: {
		helm.#CreateParentChart & {
			input: {
				name:      _args.name
				subcharts: _subChartList
			}
		}
	}

	_createEncryptedSecret: helm.#EncryptSecret & {
		input: {
			name:       _args.name
			chart:      _createParentChart.output.chart
			username:   _args.organization
			password:   _args.githubToken
			kubeconfig: _args.kubeconfig
		}
	}

	_crateRepo: github.#Push & {
		input: {
			repositoryName:      _args.vars.deploy.repoName
			contents:            _createEncryptedSecret.output.chart
			personalAccessToken: _args.githubToken
			organization:        _args.organization
			visibility:          _args.repoVisibility
			kubeconfig:          _args.kubeconfig
		}
	}

	_createApp: argocd.#CreateApp & {
		input: {
			name:               _args.name
			repositoryPassword: _args.githubToken
			repositoryURL:      _args.vars.deploy.repoURL
			appPath:            "\(name)"
			argoVar:            _args.cdVar
			waitFor:            _crateRepo.output.success && _args.waitFor
		}
	}

	// TODO: get namespace from env
	_createDevEnvironment: helm.#InstallOrUpgrade & {
		input: {
			name:       _args.name
			namespace:  "dev"
			path:       "/" + _args.name
			set:        "global.nocalhost.enabled=true"
			chart:      _createEncryptedSecret.output.chart
			kubeconfig: _args.kubeconfig
			waitFor:    _createApp.output.success
		}
	}

	// TODO: wait for resources are really created
	_writeStates: state.#Write & {
		input: {
			domain:     _args.domain
			kubeconfig: _args.kubeconfig
			frameworks: _args.frameworks
			vars:       _args.vars
			waitFor:    _createDevEnvironment.output.success
		}
	}
}
