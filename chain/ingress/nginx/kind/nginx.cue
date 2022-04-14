package kind

import (
	"github.com/h8r-dev/cuelib/deploy/kubectl"
)

#Instance: {
	input:   #Input
	install: kubectl.#Apply & {
		url:        input.url
		namespace:  input.namespace
		kubeconfig: input.kubeconfig
		waitFor:    input.waitFor
	}
	output: #Output & {
		image:   install.output
		success: install.success
	}
}
