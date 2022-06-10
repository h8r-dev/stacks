package stack

import (
	"dagger.io/dagger"

	utilsKubeconfig "github.com/h8r-dev/stacks/cuelib/internal/utils/kubeconfig"
	"github.com/h8r-dev/stacks/cuelib/component/framework"
	"github.com/h8r-dev/stacks/cuelib/component/ci"
	"github.com/h8r-dev/stacks/cuelib/component/deploy"
)

#Install: {
	args: {
		name:           string
		domain:         string
		networkType:    string
		repoVisibility: string
		organization:   string
		githubToken:    dagger.#Secret
		kubeconfig:     dagger.#Secret
		frameworks: [...]
		addons: [...]
	}

	_transformKubeconfig: utilsKubeconfig.#TransformToInternal & {
		input: {
			kubeconfig: args.kubeconfig
		}
	}

	_initRepositories: {
		_initFrameworks: {
			for idx, f in args.frameworks {
				(f.name): framework.#Init & {
					name: f.name
				}
			}
		}
		_addCIWorkflows: {
			for idx, f in args.frameworks {
				(f.name): ci.#AddWorkflow & {
					sourceCode: _initFrameworks[(f.name)].sourceCode
					name:       f.name
				}
			}
		}
	}

	_pushRepositories: {

	}

	_deployApplication: init: deploy.#Init & {
		name:       args.name
		frameworks: args.frameworks
	}

	_config: {
		for idx, f in args.frameworks {
			(f.name): framework.#Config & {
				name:   f.name
				addons: args.addons
			}
		}
	}
}
