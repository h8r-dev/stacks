package deploy

import (
	"dagger.io/dagger"

	"github.com/h8r-dev/stacks/cuelib/component/cd/argocd"
	"github.com/h8r-dev/stacks/cuelib/component/scm/github"
	"github.com/h8r-dev/stacks/cuelib/component/deploy/helm"
	"github.com/h8r-dev/stacks/cuelib/internal/base"
	"github.com/h8r-dev/stacks/cuelib/internal/var"
)

#Init: {
	input: {
		name:           string
		domain:         string
		repoVisibility: string
		organization:   string
		githubToken:    dagger.#Secret
		kubeconfig:     dagger.#Secret
		vars:           var.#Generator
		cdVar:          dagger.#Secret
		frameworks: [...]
	}

	_createHelmChart: {
		for f in input.frameworks {
			(f.name): helm.#CreateChart & {
				"input": {
					name:     input.vars[(f.name)].repoName
					appName:  input.name
					starter:  base.HelmStarter[(f.name)]
					repoURL:  input.vars[(f.name)].repoURL
					imageURL: input.vars[(f.name)].imageURL
				}
			}
		}
	}

	_subChartList: [ for f in input.frameworks {
		_createHelmChart[(f.name)].output.chart
	}]

	_createParentChart: {
		helm.#CreateParentChart & {
			"input": {
				name:      input.name
				subcharts: _subChartList
			}
		}
	}

	_createEncryptedSecret: helm.#EncryptSecret & {
		"input": {
			name:       input.name
			chart:      _createParentChart.output.chart
			username:   input.organization
			password:   input.githubToken
			kubeconfig: input.kubeconfig
		}
	}

	_crateRepo: github.#Push & {
		"input": {
			repositoryName:      input.vars.deploy.repoName
			contents:            _createEncryptedSecret.output.chart
			personalAccessToken: input.githubToken
			organization:        input.organization
			visibility:          input.repoVisibility
			kubeconfig:          input.kubeconfig
		}
	}

	_createApp: argocd.#CreateApp & {
		"input": {
			name:               input.name
			repositoryPassword: input.githubToken
			repositoryURL:      input.vars.deploy.repoURL
			appPath:            "\(name)"
			argoVar:            input.cdVar
			waitFor:            _crateRepo.output.success
		}
	}
}
