package cloud

import (
	"github.com/h8r-dev/stacks/cuelib/deploy/helm"
)

#Instance: {
	input:   #Input
	install: helm.#Chart & {
		name:         "ingress-nginx"
		repository:   input.repository
		chart:        "ingress-nginx"
		namespace:    input.namespace
		action:       input.action
		kubeconfig:   input.kubeconfig
		values:       input.values
		wait:         input.wait
		chartVersion: input.version
		waitFor:      input.waitFor
	}
	output: #Output & {
		image:   install.output
		success: install.success
	}
}
