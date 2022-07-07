package service

import (
	"github.com/h8r-dev/stacks/chain/v3/internal/utils/echo"
)

#Init: {
	args: _
	for s in args.application.service {
		(s.name): #Config & s
	}
}

#Config: {
	...
	name: string
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
		_echo:    echo.#Run & {
			msg: "create repo for " + name
		}
		// TODO use v3 codes
	}
}
