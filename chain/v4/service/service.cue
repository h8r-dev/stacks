package service

import (
	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"universe.dagger.io/bash"
	"universe.dagger.io/docker"
	"github.com/h8r-dev/stacks/chain/v4/internal/base"
	"github.com/h8r-dev/stacks/chain/v4/service/code"
	"github.com/h8r-dev/stacks/chain/v4/service/dockerfile"
	"github.com/h8r-dev/stacks/chain/v4/service/workflow"
	"github.com/h8r-dev/stacks/chain/v4/service/repository"
	"github.com/h8r-dev/stacks/chain/v4/pkg/git"
)

#Init: {
	args: _
	for s in args.application.service {
		(s.name): #Config & {
			service:      s
			appName:      args.application.name
			organization: args.scm.organization
			githubToken:  args.internal.githubToken
		}
	}
}

#Config: {
	appName:      string
	organization: string
	githubToken:  dagger.#Secret
	service: {
		scaffold: bool
		name:     string
		type:     string
		language: {
			name:    string
			version: string
		}
		framework: string
		setting: {
			...
		}
		repo: {
			url:        string
			visibility: string
		}
		...
	}

	_isGenerated: service.scaffold
	_code: {
		output: dagger.#FS
		...
	}
	_wait: bool
	{
		_isGenerated: false
		_source:      git.#Pull & {
			remote: service.repo.url
			ref:    "main"
			token:  githubToken
		}
		_code: output: _source.output
		_wait: true
		_pr:   git.#PR & {
			input:          _assemble.export.directories."/workdir/source"
			name:           service.name
			"organization": organization
			token:          githubToken
		}
	} | {
		_isGenerated: true
		_source:      code.#Source & {
			framework: service.framework
		}
		_init: git.#Init & {
			input: _source.output
		}
		_code: output: _init.output
		_createRepo: repository.#Create & {
			name:           service.name
			"organization": organization
			visibility:     service.repo.visibility
			token:          githubToken
		}
		_wait: _createRepo.wait
		_push: git.#Push & {
			input:          _assemble.export.directories."/workdir/source"
			name:           service.name
			"organization": organization
			token:          githubToken
		}
	}
	_dockerfile: {
		output:  _source.output
		_source: dockerfile.#Generate & {
			language: service.language.name
			version:  service.language.version
			setting:  service.setting
		}
	}
	_workflow: {
		output:  _source.output
		_source: workflow.#Generate & {
			"appName":      appName
			"organization": organization
			helmRepo:       appName + "-deploy"
			wantedFileName: appName + "-docker-publish.yaml"
		}
	}
	_sh: core.#Source & {
		path: "."
		include: ["assemble.sh"]
	}
	_deps: docker.#Build & {
		steps: [
			base.#Image,
			docker.#Copy & {
				contents: _code.output
				dest:     "/workdir/source"
			},
		]
	}
	_assemble: bash.#Run & {
		input:   _deps.output
		always:  true
		workdir: "/workdir"
		mounts: {
			workflow: {
				dest:     "/workdir/workflow"
				type:     "fs"
				contents: _workflow.output
			}
			dockerfile: {
				dest:     "/workdir/dockerfile"
				type:     "fs"
				contents: _dockerfile.output
			}
		}
		env: WAIT: "\(_wait)"
		script: {
			directory: _sh.output
			filename:  "assemble.sh"
		}
		export: directories: "/workdir/source": _
	}
	_secret: repository.#SetSecret & {
		name:           service.name
		"organization": organization
		token:          githubToken
		key:            "PAT"
		value:          githubToken
		wait:           _wait
	}
}
