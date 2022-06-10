package stacks

import (
	"dagger.io/dagger"

	utilsKubeconfig "github.com/h8r-dev/stacks/cuelib/internal/utils/kubeconfig"
	"github.com/h8r-dev/stacks/cuelib/framework"
	"github.com/h8r-dev/stacks/cuelib/ci"
	"github.com/h8r-dev/stacks/cuelib/deploy"
	"github.com/h8r-dev/stacks/cuelib/scm/github"
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
		input: utilsKubeconfig.#Input & {
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
		test: github.#Push & {
			input: {
				repositoryName:      "\(args.name)-mock-repo"
				personalAccessToken: args.githubToken
				organization:        args.organization
				visibility:          args.repoVisibility
				kubeconfig:          _transformKubeconfig.output.kubeconfig
			}
		}
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
