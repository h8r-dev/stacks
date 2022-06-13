package test

import (
	"dagger.io/dagger"
	"universe.dagger.io/bash"

	"github.com/h8r-dev/stacks/cuelib/component/deploy/helm"
	"github.com/h8r-dev/stacks/cuelib/internal/base"
)

dagger.#Plan & {
	actions: {
		_baseImage: base.#Image

		_createChart1: helm.#CreateChart & {
			input: {
				name:    "chart1"
				appName: "test"
				set: """
					'.image.repository = "rep" | .image.tag = "tag"'
					"""
			}
		}

		_createChart2: helm.#CreateChart & {
			input: {
				name:    "chart2"
				appName: "test"
				starter: "helm-starter/go/gin"
			}
		}

		_subChartList: [_createChart1.output.chart, _createChart2.output.chart]

		_createParentChart: {
			helm.#CreateParentChart & {
				"input": {
					name:      "test-chart"
					subcharts: _subChartList
				}
			}
		}

		test: bash.#Run & {
			input: _baseImage.output
			script: contents: """
				ls -laR /helm
				"""
			mounts: helm: {
				dest:     "/helm"
				contents: _createParentChart.output.chart
			}
		}
	}
}
