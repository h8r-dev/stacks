package deploy

import (
	"github.com/h8r-dev/stacks/chain/v3/internal/utils/echo"
)

#Init: {
	args: _
	for m in args.middleware {
		(m.name): #Config & m
	}
}

#Config: {
	...
	{
		type:  "postgres"
		_echo: echo.#Run & {
			msg: "enable postgres"
		}
	} | {
		type:  "redis"
		_echo: echo.#Run & {
			msg: "enable redis"
		}
	}
}
