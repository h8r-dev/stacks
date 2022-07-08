package plans

import (
	"dagger.io/dagger"
	"github.com/h8r-dev/stacks/chain/v4/forkenv"
)

dagger.#Plan & {
	client: {

	}
	actions: up: forkenv.#Fork & {

	}
}
