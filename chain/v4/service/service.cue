package service

import (
	"dagger.io/dagger"
	"universe.dagger.io/bash"
	"github.com/h8r-dev/stacks/chain/v3/internal/base"
	"github.com/h8r-dev/stacks/chain/v4/service/code"
	"github.com/h8r-dev/stacks/chain/v4/service/dockerfile"
	"github.com/h8r-dev/stacks/chain/v4/service/workflow"
	"github.com/h8r-dev/stacks/chain/v4/pkg/git"
)

// TODO set PAT, assemble codes and push codes

#Init: {
	args: _
	for s in args.application.service {
		(s.name): #Config & {
			service:      s
			appName:      args.application.name
			organization: args.scm.organization
			githubToken:  args.scm.token
		}
	}
}

#Config: {
	appName:      string
	organization: string
	githubToken:  string
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
	_deps:        base.#Image
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
	} | {
		_isGenerated: true
		_source:      code.#Source & {
			framework: service.framework
		}
		_init: git.#Init & {
			input: _source.output
		}
		_code: output: _init.output
		_createRepo: git.#Create & {
			name:           service.name
			"organization": organization
			visibility:     service.repo.visibility
			token:          githubToken
		}
		_wait: _createRepo.wait
	}
	_dockerfile: {
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

	_assemble: bash.#Run & {
		input:   _deps.output
		always:  true
		workdir: "/workdir"
		mounts: {
			sourcecode: {
				dest:     "/workdir/source"
				type:     "fs"
				contents: _code.output
			}
			workflow: {
				dest:     "/workdir/workflow"
				type:     "fs"
				contents: _workflow.output
			}
		}
		env: WAIT:        "\(_wait)"
		script: contents: "ls -lah source"
	}
}
