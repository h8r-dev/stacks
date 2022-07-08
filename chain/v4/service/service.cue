package service

import (
	"universe.dagger.io/bash"
	"github.com/h8r-dev/stacks/chain/v3/internal/utils/echo"
	"github.com/h8r-dev/stacks/chain/v3/internal/base"
	"github.com/h8r-dev/stacks/chain/v4/service/source"
)

#Init: {
	args: _
	for s in args.application.service {
		(s.name): #Config & s
	}
}

#Config: {
	name: string
	type: string
	language: {
		name:    string
		version: string
	}
	framework: string

	_deps: base.#Image

	{
		scaffold: false
		_echo:    echo.#Run & {
			msg: "don't create repo for " + name
		}
		// TODO Generate Dockerfile
		// TODO Generate github workflow
		// TODO add files to the source code
		// TODO commit changes and push back
	} | {
		scaffold: true
		_init:    source.#Init & {"framework": framework}

		_ls: bash.#Run & {
			input:   _deps.output
			workdir: "/workdir"
			mounts: sourcecode: {
				dest:     "/workdir"
				type:     "fs"
				contents: _init.output
			}
			script: contents: "ls -lah"
		}

		_echo: echo.#Run & {
			msg: "create repo for " + name
		}
		// TODO use v3 codes
	}
	...
}
