package test

import (
	"dagger.io/dagger"
	"universe.dagger.io/bash"

	"github.com/h8r-dev/stacks/cuelib/component/framework/helm"
	"github.com/h8r-dev/stacks/cuelib/internal/base"
)

dagger.#Plan & {
	actions: {
		_baseImage: base.#Image

		_createChart1: helm.#Create & {
			input: {
				name:    "chart1"
				appName: "test"
				set: """
					'.image.repository = "rep" | .image.tag = "tag"'
					"""
			}
		}

		_createChart2: helm.#Create & {
			input: {
				name:           "chart2"
				appName:        "test"
				starter:        "helm-starter/go/gin"
				contents:       _createChart1.output.fs
				mergeAllCharts: true
			}
		}

		test: bash.#Run & {
			input: _baseImage.output
			script: contents: """
				ls -laR /helm
				"""
			mounts: "helm": {
				dest:     "/helm"
				contents: _createChart2.output.fs
			}
		}
	}
}
