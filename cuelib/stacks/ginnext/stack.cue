package ginnext

import (
	"github.com/h8r-dev/stacks/cuelib/framework/registry"
	"github.com/h8r-dev/stacks/cuelib/ci"
	"github.com/h8r-dev/stacks/cuelib/deploy"
)

#Install: {
	args: {
		name:        string
		domain:      string
		githubToken: string
		frameworks: [...]
		addons: [...]
	}

	_initRepositories: {
		_initFrameworks: {
			for idx, framework in args.frameworks {
				(framework.name): registry.#Init & {
					name: framework.name
				}
			}
		}
		_addCIWorkflows: {
			for idx, framework in args.frameworks {
				(framework.name): ci.#AddWorkflow & {
					sourceCode: _initFrameworks[(framework.name)].sourceCode
					name:       framework.name
				}
			}
		}
	}

	_pushRepositories: {

	}

	_deployApplication: {
		init: deploy.#Init & {
			name:       args.name
			frameworks: args.frameworks
		}
	}

	_config: {
		for idx, framework in args.frameworks {
			(framework.name): registry.#Config & {
				name:   framework.name
				addons: args.addons
			}
		}
	}
}
