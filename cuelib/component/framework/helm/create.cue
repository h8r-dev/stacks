package helm

import (
	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"universe.dagger.io/bash"
	"universe.dagger.io/docker"

	"github.com/h8r-dev/stacks/cuelib/internal/base"
)

#Create: {
	input: {
		name:      string
		contents?: dagger.#FS
		// Helm values set
		// Format: '.image.repository = "rep" | .image.tag = "tag"'
		set?: string | *""
		// Helm starter scaffold
		starter?:               string | *""
		domain:                 base.#DefaultDomain
		gitOrganization?:       string
		appName:                string
		ingressHostPath:        string | *"/"
		rewriteIngressHostPath: bool | *false
		mergeAllCharts:         bool | *false
		repositoryType:         string | *"frontend" | "backend" | "deploy"
	}

	output: {
		fs:      dagger.#FS
		success: bool | *true
	}

	_deps: docker.#Build & {
		steps: [
			base.#Image,
			if input.contents != _|_ {
				docker.#Copy & {
					contents: input.contents
					dest:     "/helm"
				}
			},
		]
	}

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
			MERGE_ALL_CHARTS:          "\(input.mergeAllCharts)"
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

	output: {
		fs: _run.export.directories."/helm"
	}
}
