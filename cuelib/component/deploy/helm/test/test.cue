package test

import (
	"dagger.io/dagger"
	"universe.dagger.io/bash"

	utilsKubeconfig "github.com/h8r-dev/stacks/cuelib/internal/utils/kubeconfig"
	"github.com/h8r-dev/stacks/cuelib/component/deploy/helm"
	"github.com/h8r-dev/stacks/cuelib/internal/base"
)

dagger.#Plan & {
	client: {
		commands: kubeconfig: {
			name: "cat"
			args: [env.KUBECONFIG]
			stdout: dagger.#Secret
		}
		env: {
			KUBECONFIG: string
			PASSWORD:   dagger.#Secret
		}
	}

	actions: {

		_transformKubeconfig: utilsKubeconfig.#TransformToInternal & {
			input: kubeconfig: client.commands.kubeconfig.stdout
		}

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
				input: {
					name:      "test-chart"
					subcharts: _subChartList
				}
			}
		}

		_createEncryptedSecret: helm.#EncryptSecret & {
			input: {
				name:       "test-chart"
				chart:      _createParentChart.output.chart
				username:   "test"
				password:   client.env.PASSWORD
				kubeconfig: _transformKubeconfig.output.kubeconfig
			}
		}

		test: bash.#Run & {
			input: _baseImage.output
			script: contents: """
				ls -laR /helm
				cat /helm/test-chart/templates/sealed-image-pull-secret.yaml
				"""
			mounts: helm: {
				dest:     "/helm"
				contents: _createEncryptedSecret.output.chart
			}
		}
	}
}
