package helm

import (
	"strconv"
	"universe.dagger.io/bash"
	"dagger.io/dagger/core"
)

#Instance: {
	defaultStarter: {
		url:      "https://github.com/h8r-dev/helm-starter.git"
		repoName: "helm-starter"
		version:  "v0.0.1"
	}
	input: #Input
	src:   core.#Source & {
		path: "."
	}
	do: bash.#Run & {
		env: {
			NAME: input.chartName
			if input.set != _|_ {
				HELM_SET: input.set
			}
			DIR_NAME:          input.name
			STARTER_REPO_URL:  defaultStarter.url
			STARTER_REPO_NAME: defaultStarter.repoName
			STARTER_REPO_VER:  defaultStarter.version
			if input.starter != _|_ {
				STARTER: input.starter
			}
			if input.gitOrganization != _|_ {
				GIT_ORGANIZATION: input.gitOrganization
			}
			APP_NAME:                  input.appName
			APPLICATION_DOMAIN:        input.domain.application.domain
			INGRESS_HOST_PATH:         input.ingressHostPath
			REWRITE_INGRESS_HOST_PATH: strconv.FormatBool(input.rewriteIngressHostPath)
			MERGE_ALL_CHARTS:          strconv.FormatBool(input.mergeAllCharts)
			REPOSITORY_TYPE:           input.repositoryType
		}
		"input": input.image
		// helm deploy dir path
		workdir: "/scaffold/\(input.name)"
		script: {
			directory: src.output
			filename:  "helm-create-merge.sh"
		}
	}
	// _outputHelm: core.#Subdir & {
	//  "input": _build.output.rootfs
	//  path:    "/tmp/\(input.chartName)"
	// }
	// do: docker.#Copy & {
	//  "input":  input.image
	//  contents: _outputHelm.output
	//  dest:     "/scaffold/\(input.name)/\(input.chartName)"
	// }
	output: #Output & {
		image: do.output
	}
}
