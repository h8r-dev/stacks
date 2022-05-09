package h8r

import (
	"dagger.io/dagger"
	"github.com/h8r-dev/stacks/chain/internal/h8r/h8r"
	"github.com/h8r-dev/stacks/chain/internal/utils/random"
)

dagger.#Plan & {
	client: {
	}

	actions: test: {
		randomString: random.#String & {

		}

		uri:  randomString.output
		name: uri + "-testcase"

		create: h8r.#CreateH8rIngress & {
			"name": name
			host:   "1.1.1.1"
			domain: uri + ".testcase.stack.h8r.io"
		}

		delete: h8r.#DeleteH8rIngress & {
			"name":  name
			waitFor: create.success
		}
	}
}
