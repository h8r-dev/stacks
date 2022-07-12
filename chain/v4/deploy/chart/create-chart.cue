package chart

import (
	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"universe.dagger.io/bash"
	"github.com/h8r-dev/stacks/chain/v4/internal/base"
	"github.com/h8r-dev/stacks/chain/v4/internal/var"
)

#Create: {
	input: {
		name: string
		// Helm values set
		// Format: '.image.repository = "rep" | .image.tag = "tag"'
		set?: string | *""
		// Helm starter
		starter?:               string | *""
		domain:                 string | *"h8r.site"
		deploymentEnv:          string | *""
		appName:                string
		ingressHostPath:        string | *"/"
		rewriteIngressHostPath: bool | *false
		repoURL:                string
		imageURL:               string
	}

	output: {
		chart:   dagger.#FS
		success: bool | *true
	}

	_deps: base.#Image

	_sh: core.#Source & {
		path: "."
		include: ["create-chart.sh"]
	}

	_starter: var.#HelmStarter

	_run: bash.#Run & {
		env: {
			NAME: input.name
			if input.set != _|_ {
				HELM_SET: input.set
			}
			STARTER_REPO_URL:  _starter.url
			STARTER_REPO_NAME: _starter.repoName
			STARTER_REPO_VER:  _starter.version
			if input.starter != _|_ {
				STARTER: input.starter
			}
			APP_NAME:                  input.appName
			APPLICATION_DOMAIN:        input.domain
			INGRESS_HOST_PATH:         input.ingressHostPath
			REWRITE_INGRESS_HOST_PATH: "\(input.rewriteIngressHostPath)"
			GIT_URL:                   input.repoURL
			IMAGE_URL:                 input.imageURL
			DEPLOYMENT_ENV:            input.deploymentEnv
		}
		"input": _deps.output
		workdir: "/helm"
		script: {
			directory: _sh.output
			filename:  "create-chart.sh"
		}
		export: directories: "/helm": _
	}

	output: chart: _run.export.directories."/helm"
}
