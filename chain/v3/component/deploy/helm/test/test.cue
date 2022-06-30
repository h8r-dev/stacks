package test

import (
	"dagger.io/dagger"
	"universe.dagger.io/bash"
	"github.com/h8r-dev/stacks/chain/v3/component/deploy/helm"
	"github.com/h8r-dev/stacks/chain/v3/internal/base"
	utilsKubeconfig "github.com/h8r-dev/stacks/chain/v3/internal/utils/kubeconfig"
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
				name:     "chart1"
				imageURL: "chart1"
				appName:  "test"
				set: """
					'.image.repository = "rep" | .image.tag = "tag"'
					"""
			}
		}

		_createChart2: helm.#CreateChart & {
			input: {
				name:     "chart2"
				imageURL: "chart1"
				appName:  "test"
				starter:  "helm-starter/go/gin"
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
				"""
			mounts: helm: {
				dest:     "/helm"
				contents: _createParentChart.output.chart
			}
		}

		testHelm: {
			local: helm.#InstallOrUpgrade & {
				input: {
					name:       "test"
					namespace:  "test2"
					path:       "/test-chart"
					set:        "global.nocalhost.enabled=true"
					chart:      _createParentChart.output.chart
					kubeconfig: _transformKubeconfig.output.kubeconfig
				}
			}
			repo: helm.#InstallOrUpgrade & {
				input: {
					name:       "ng-test"
					namespace:  "test2"
					repo:       "https://charts.bitnami.com/bitnami"
					chart:      "nginx"
					kubeconfig: _transformKubeconfig.output.kubeconfig
				}
			}
		}
	}
}
