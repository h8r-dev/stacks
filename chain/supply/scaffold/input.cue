package scaffold

import (
	"github.com/h8r-dev/chain/supply/base"
)

#Input: {
	provider:     string | *"github"
	organization: string
	repository: [...base.#Repository]
	addons?: [...base.#Addons]
}
