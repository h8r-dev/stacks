package h8r

import (
	"dagger.io/dagger"
	"github.com/h8r-dev/stacks/cuelib/h8r/h8r"
	"github.com/h8r-dev/stacks/cuelib/utils/random"
)

dagger.#Plan & {
	client: {
		// commands: kubeconfig: {
		//  name: "cat"
		//  args: ["\(env.KUBECONFIG)"]
		//  stdout: dagger.#Secret
		// }
		// env: KUBECONFIG: string
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
