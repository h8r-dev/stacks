package deploy

import (
	"github.com/h8r-dev/stacks/cuelib/component/deploy/helm"
	"github.com/h8r-dev/stacks/cuelib/internal/base"
)

#Init: {
	input: {
		name:           string
		domain:         string
		repoVisibility: string
		organization:   string
		githubToken:    dagger.#Secret
		kubeconfig:     dagger.#Secret
		frameworks: [...]
	}
	output: chart: _createParentChart.output.fs

	_createHelmChart: {
		for f in input.frameworks {
			(f.name): helm.#CreateChart & {
				"input": {
					name:    f.name
					appName: input.name
					starter: base.HelmStarter[(f.name)]
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

	_push: github.#Push & {
		input: {
			repositoryName:      "helm-test"
			contents:            _createParentChart.output.fs
			personalAccessToken: args.githubToken
			organization:        args.organization
			visibility:          args.repoVisibility
			kubeconfig:          _transformKubeconfig.output.kubeconfig
		}
	}
}
