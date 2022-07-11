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
		(s.name): #Config & {
			service:      s
			appName:      args.application.name
			organization: args.scm.organization
		}
	}
}

#Config: {
	appName:      string
	organization: string
	service: {
		scaffold: bool
		name:     string
		type:     string
		language: {
			name:    string
			version: string
		}
		framework: string
		...
	}

	_isGenerated: service.scaffold
	_deps:        base.#Image

	{
		_isGenerated: false
		_echo:        echo.#Run & {
			msg: "don't create repo for " + service.name
		}
		// TODO Generate Dockerfile
		// TODO Generate github workflow
		// TODO add files to the source code
		// TODO commit changes and push back
	} | {
		_isGenerated: true
		_code:        code.#Source & {
				framework: service.framework
		}

		_check: bash.#Run & {
			input:   _deps.output
			workdir: "/workdir"
			// always:  true // FIXME debug
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
			script: contents: "ls workflow"
		}
	}

	_workflow: {
		output:  _source.output
		_source: workflow.#Generate & {
			"appName":      appName
			"organization": organization
			helmRepo:       appName + "-deploy"              // HACK this is a variable
			wantedFileName: appName + "-docker-publish.yaml" // HACK this is a variable
		}
	}

	_assemble: echo.#Run & {msg: "assemble all these things"}
}
