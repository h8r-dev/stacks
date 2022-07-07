package repository

import (
	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"github.com/h8r-dev/stacks/chain/v3/component/ci"
	"github.com/h8r-dev/stacks/chain/v3/component/framework"
	"github.com/h8r-dev/stacks/chain/v3/component/scm/github"
	"github.com/h8r-dev/stacks/chain/v3/internal/var"
	"github.com/h8r-dev/stacks/chain/v3/pkg/wait"
)

#Create: {
	input: {
		appName:         string
		scmOrganization: string
		repoVisibility:  string
		githubToken:     dagger.#Secret
		kubeconfig:      dagger.#Secret
		vars:            var.#Generator
		frameworks: [...]
		initRepos: string
		services: [...]
	}

	_args: input

	_repo: {
		for f in input.frameworks {
			(f.name): {
				_code: framework.#Init & {
					name: f.name
				}
				_addWorkflow: ci.#AddWorkflow & {
					input: {
						applicationName:  _args.appName
						organization:     _args.scmOrganization
						deployRepository: _args.vars.deploy.repoName
						sourceCode:       _code.output.sourceCode
					}
				}
				_push: github.#Push & {
					input: {
						initRepo:            _args.initRepos
						repositoryName:      _args.vars[(f.name)].repoName
						contents:            _addWorkflow.output.sourceCode
						personalAccessToken: _args.githubToken
						organization:        _args.scmOrganization
						visibility:          _args.repoVisibility
						kubeconfig:          _args.kubeconfig
					}
				}
				output: success: _push.output.success
			}
		}
	}

	_addci: {
		for s in _args.services {
			(s.name): {
				_code: core.#GitPull & {
					remote:     _args.vars.msvcs[(s.name)].repoURL
					ref:        "main"
					keepGitDir: true
					auth: authToken: _args.githubToken
				}
				_addWorkflow: ci.#AddWorkflow & {
					input: {
						applicationName:  _args.appName
						organization:     _args.scmOrganization
						deployRepository: _args.vars.deploy.repoName
						sourceCode:       _code.output
						fileName:         "\(_args.appName)-docker-publish.yaml"
					}
				}
				_push: github.#GitPush & {
					input: {
						sourceCode:   _addWorkflow.output.sourceCode
						repository:   s.repository
						organization: _args.scmOrganization
						githubToken:  _args.githubToken
					}
				}
			}
		}
	}

	_wait: {
		_list: [ for f in input.frameworks {
			_repo[(f.name)].output.success
		}]
		wait.#List & {
			list: _list
			name: "repo"
		}
	}

	output: success: _wait.success
}
