package service

import (
	"universe.dagger.io/bash"
	"github.com/h8r-dev/stacks/chain/v3/internal/utils/echo"
	"github.com/h8r-dev/stacks/chain/v3/internal/base"
	"github.com/h8r-dev/stacks/chain/v4/service/code"
	"github.com/h8r-dev/stacks/chain/v4/service/workflow"
)

#Init: {
	args: _
	for s in args.application.service {
		(s.name): #Config & s & {
			appName:      args.application.name
			organization: args.scm.organization
		}
	}
}

#Config: {
	// TODO wrap args
	appName:      string
	organization: string

	scaffold: bool
	name:     string
	type:     string
	language: {
		name:    string
		version: string
	}
	framework: string

	_isGenerated: scaffold
	_deps:        base.#Image

	{
		_isGenerated: false
		_echo:        echo.#Run & {
			msg: "don't create repo for " + name
		}
		// TODO Generate Dockerfile
		// TODO Generate github workflow
		// TODO add files to the source code
		// TODO commit changes and push back
	} | {
		_isGenerated: true
		_code:        code.#Source & {"framework": framework}

		_check: bash.#Run & {
			input:   _deps.output
			workdir: "/workdir"
			mounts: sourcecode: {
				dest:     "/workdir"
				type:     "fs"
				contents: _code.output
			}
			script: contents: "ls -lah"
		}
	}

	_workflow: _source: workflow.#Generate & {
		"appName":      appName
		"organization": organization
		helmRepo:       "helm"
	}

	_assemble: echo.#Run & {msg: "assemble all these things"}
	...
}
