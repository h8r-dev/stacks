package stack

import (
	"dagger.io/dagger"

	utilsKubeconfig "github.com/h8r-dev/stacks/cuelib/internal/utils/kubeconfig"
	"github.com/h8r-dev/stacks/cuelib/component/framework"
	// "github.com/h8r-dev/stacks/cuelib/component/scm/github"
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
		input: kubeconfig: args.kubeconfig
	}

	_initRepositories: {
		for idx, f in args.frameworks {
			(f.name): {
				_code: framework.#Init & {
					name: f.name
				}
				_addWorkflow: ci.#AddWorkflow & {
					input: {
						applicationName:  args.name
						organization:     args.organization
						deployRepository: "TODO-deploy"
						sourceCode:       _code.output.sourceCode
					}
				}
				// _push: github.#Push & {
				//  input: {
				//   repositoryName:      "\(args.name)-\(f.name)"
				//   contents:            _addWorkflow.output.sourceCode
				//   personalAccessToken: args.githubToken
				//   organization:        args.organization
				//   visibility:          args.repoVisibility
				//   kubeconfig:          _transformKubeconfig.output.kubeconfig
				//  }
				// }
			}
		}
	}

	_deployApplication: {
		_init: deploy.#Init & {
			input: {
				name:       args.name
				frameworks: args.frameworks
			}
		}
		// _push: github.#Push & {
		//  input: {
		//   repositoryName:      "helm-test"
		//   contents:            _init.output.chart
		//   personalAccessToken: args.githubToken
		//   organization:        args.organization
		//   visibility:          args.repoVisibility
		//   kubeconfig:          _transformKubeconfig.output.kubeconfig
		//  }
		// }
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
