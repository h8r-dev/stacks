package test

import (
	"dagger.io/dagger"
	"github.com/h8r-dev/stacks/chain/v4/deploy/chart"
	"github.com/h8r-dev/stacks/chain/v4/internal/base"
	"github.com/h8r-dev/stacks/chain/v4/pkg/k8s/helm"
	"github.com/h8r-dev/stacks/chain/v4/pkg/k8s/kubeconfig"
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

		_transformKubeconfig: kubeconfig.#TransformToInternal & {
			input: kubeconfig: client.commands.kubeconfig.stdout
		}
		_kubeconfig: _transformKubeconfig.output.kubeconfig

		_baseImage: base.#Image

		_createChart1: chart.#Create & {
			input: {
				name:     "chart1"
				imageURL: "chart1"
				appName:  "test"
				repoURL:  "http://github.com/test"
				set: """
					'.image.repository = "rep" | .image.tag = "tag"'
					"""
			}
		}

		_createChart2: chart.#Create & {
			input: {
				name:     "chart2"
				imageURL: "chart1"
				repoURL:  "http://github.com/test"
				appName:  "test"
				starter:  "helm-starter/go/gin"
			}
		}

		_subChartList: [_createChart1.output.chart, _createChart2.output.chart]

		_createParentChart: {
			chart.#CreateParent & {
				input: {
					name:      "test-chart"
					subcharts: _subChartList
				}
			}
		}

		_createEncryptedSecret: chart.#EncryptSecret & {
			input: {
				name:       "test-chart"
				chart:      _createParentChart.output.chart
				username:   "test"
				password:   client.env.PASSWORD
				kubeconfig: _kubeconfig
			}
		}

		test: helm.#InstallOrUpgrade & {
			input: {
				name:      "test-chart"
				namespace: "test2"
				path:      "/test-chart"
				values: """
					global:
					  nocalhost:
					    enabled: true
					"""
				chart:      _createEncryptedSecret.output.chart
				kubeconfig: _kubeconfig
			}
		}
	}
}
