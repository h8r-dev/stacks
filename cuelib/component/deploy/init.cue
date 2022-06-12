package deploy

import (
	"github.com/h8r-dev/stacks/cuelib/component/framework/helm"
	"github.com/h8r-dev/stacks/cuelib/internal/base"
)

#Init: {
	input: {
		name: string
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
		_createHelmChart[(f.name)].output.fs
	}]

	_createParentChart: {
		helm.#CreateParentChart & {
			"input": {
				name:      input.name
				subcharts: _subChartList
			}
		}
	}
}
