package stack

import (
	"dagger.io/dagger"

	"github.com/h8r-dev/stacks/cuelib/internal/var"
	utilsKubeconfig "github.com/h8r-dev/stacks/cuelib/internal/utils/kubeconfig"
	"github.com/h8r-dev/stacks/cuelib/component/framework"
	// "github.com/h8r-dev/stacks/cuelib/component/scm/github"
	"github.com/h8r-dev/stacks/cuelib/component/ci"
	"github.com/h8r-dev/stacks/cuelib/component/deploy"
	// "github.com/h8r-dev/stacks/cuelib/internal/utils/echo"
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

	_var: var.#Generator & {
		input: {
			applicationName: args.name
			domain:          args.domain
			networkType:     args.networkType
			organization:    args.organization
			frameworks:      args.frameworks
			addons:          args.addons
		}
	}

	// _echo: echo.#Run & {
	//  msg: _var.gin.repoURL
	// }

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

	_deployApp: deploy.#Init & {
		input: {
			name:           args.name
			domain:         args.domain
			repoVisibility: args.repoVisibility
			organization:   args.organization
			githubToken:    args.githubToken
			kubeconfig:     _transformKubeconfig.output.kubeconfig
			frameworks:     args.frameworks
			vars:           _var
		}
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
