package dockerfile

import (
	"github.com/h8r-dev/stacks/chain/v3/internal/utils/echo"
)

#Generate: {
	language: "golang"
	setting: {
		extension: {
			entryFile: string
			...
		}
		...
	}
	_echo: echo.#Run & {
		msg: setting.extension.entryFile
	}
	...
} | {
	language: "typescript"
	...
}
