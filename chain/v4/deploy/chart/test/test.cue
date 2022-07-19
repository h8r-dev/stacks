package test

import (
	"encoding/yaml"
	"dagger.io/dagger"
	"github.com/h8r-dev/stacks/chain/v4/deploy/chart"
	"github.com/h8r-dev/stacks/chain/v4/internal/base"
	"github.com/h8r-dev/stacks/chain/v4/pkg/k8s/helm"
	"github.com/h8r-dev/stacks/chain/v4/pkg/k8s/kubeconfig"
	"github.com/h8r-dev/stacks/chain/v3/internal/utils/echo"
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
				repoURL:  "http://github.com/test/test"
				appName:  "test"
				starter:  "helm-starter/go/gin"
				imageURL: "ghcr.io/test/test"
				deploymentEnv: """
					- name: HOST
					  value: h8r.dev
					- name: PASSWORD
					  value: my_secret
					"""
				ingressValue: """
					enabled: true
					className: nginx
					hosts:
					  - host: foo.bar.com
					    paths:
					      - pathType: ImplementationSpecific
					        path: /api(/|$)(.*)
					      - pathType: ImplementationSpecific
					        path: /v1/(/|$)(.*)
					annotations:
					  nginx.ingress.kubernetes.io/rewrite-target: /$2
					tls: []
					"""
			}
		}

		testCreateChart: _createChart2

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

		_ingress: chart.#Ingress & {
			input: {
				rewrite: true
				host:    "foo.bar.com"
				paths: [
					{
						path: "/api"
					}, {
						path: "/"
					},
				]
			}
		}
		testIngress: echo.#Run & {
			msg: yaml.Marshal(_ingress.info)
		}
	}
}
