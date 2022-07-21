package stack

import (
	"dagger.io/dagger"
	"github.com/h8r-dev/stacks/chain/v4/deploy"
	"github.com/h8r-dev/stacks/chain/v4/middleware"
	"github.com/h8r-dev/stacks/chain/v4/service"
	"github.com/h8r-dev/stacks/chain/v4/update"
	"github.com/h8r-dev/stacks/chain/v4/internal/addon"
	utilsKubeconfig "github.com/h8r-dev/stacks/chain/v4/internal/kubeconfig"
)

#Install: {
	args: internal: {
		kubeconfig:    dagger.#Secret
		githubToken:   dagger.#Secret
		imagePassword: dagger.#Secret
	}

	if !args.isUpdate {
		_transformKubeconfig: utilsKubeconfig.#TransformToInternal & {
			input: kubeconfig: args.internal.kubeconfig
		}
		_kubeconfig: _transformKubeconfig.output.kubeconfig

		_infra: addon.#ReadInfraConfig & {
			input: kubeconfig: _kubeconfig
		}

		_service: service.#Init & {
			"args": args
		}

		_middleware: middleware.#Init & {
			"args": args
		}

		_deploy: deploy.#Init & {
			"args":           args
			kubeconfig:       _kubeconfig
			cdVar:            _infra.argoCD
			middlewareCharts: _middleware.output.charts
		}
	}

	if args.isUpdate {
		_update: update.#Run & {
			"args": args
		}
	}
}
