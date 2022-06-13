package helm

import (
	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"universe.dagger.io/bash"

	"github.com/h8r-dev/stacks/cuelib/internal/base"
)

#CreateChart: {
	input: {
		name: string
		// Helm values set
		// Format: '.image.repository = "rep" | .image.tag = "tag"'
		set?: string | *""
		// Helm starter
		starter?:               string | *""
		domain:                 base.#DefaultDomain
		gitOrganization?:       string
		appName:                string
		ingressHostPath:        string | *"/"
		rewriteIngressHostPath: bool | *false
		repositoryType:         string | *"frontend" | "backend" | "deploy"
	}

	output: {
		chart:   dagger.#FS
		success: bool | *true
	}

	_deps: base.#Image

	_sh: core.#Source & {
		path: "."
		include: ["create.sh"]
	}

	_starter: base.#HelmStarter

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
			if input.gitOrganization != _|_ {
				GIT_ORGANIZATION: input.gitOrganization
			}
			APP_NAME:                  input.appName
			APPLICATION_DOMAIN:        input.domain.application.domain
			INGRESS_HOST_PATH:         input.ingressHostPath
			REWRITE_INGRESS_HOST_PATH: "\(input.rewriteIngressHostPath)"
			REPOSITORY_TYPE:           input.repositoryType
		}
		"input": _deps.output
		workdir: "/helm"
		script: {
			directory: _sh.output
			filename:  "create.sh"
		}
		export: directories: "/helm": _
	}

	output: chart: _run.export.directories."/helm"
}
