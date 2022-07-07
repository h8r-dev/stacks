package stack

import (
	"dagger.io/dagger"
	"github.com/h8r-dev/stacks/chain/v4/middleware"
	"github.com/h8r-dev/stacks/chain/v4/deploy"
	utilsKubeconfig "github.com/h8r-dev/stacks/chain/v3/internal/utils/kubeconfig" // FIXME this is v3 pkg
)

#Install: {
	args: kubeconfig: dagger.#Secret

	_transformKubeconfig: utilsKubeconfig.#TransformToInternal & {
		input: kubeconfig: args.kubeconfig
	}
	_kubeconfig: _transformKubeconfig.output.kubeconfig

	_service: service.#Init & {
		"args": args
	}

	_middleware: middleware.#Init & {
		"args": args
	}
}
