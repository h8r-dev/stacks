package stack

import (
	"dagger.io/dagger"
	"github.com/h8r-dev/stacks/chain/v3/internal/utils/echo"
)

#Install: {
	args: {
		kubeconfig: dagger.#Secret
	}

	_run: {
		for s in args.application.service {
			(s.name): #Service & {
				scaffold: s.scaffold
				name:     s.name
			}
		}
	}
}

#Service: {
	name: string
	{
		scaffold: false
		_echo:    echo.#Run & {
			msg: "don't create repo for " + name
		}
	} | {
		scaffold: true
		_echo:    echo.#Run & {
			msg: "create repo for " + name
		}
	}
}
