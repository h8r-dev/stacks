package state

import (
	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"universe.dagger.io/bash"
	"universe.dagger.io/docker"
	"github.com/h8r-dev/stacks/chain/v3/internal/base"
	"github.com/h8r-dev/stacks/chain/v3/pkg/kubectl/apply"
	"github.com/h8r-dev/stacks/chain/v3/internal/var"
)

#Write: {
	input: {
		kubeconfig: dagger.#Secret
		frameworks: [...]
		vars: var.#Generator
	}

	_args: input

	_pullSh: core.#Source & {
		path: "."
		include: ["pull-crd.sh"]
	}

	_deps: docker.#Build & {
		steps: [
			base.#Image,
			bash.#Run & {
				workdir: "/src"
				script: {
					directory: _pullSh.output
					filename:  "pull-crd.sh"
				}
			},
		]
	}

	_modifyRepoSh: core.#Source & {
		path: "."
		include: ["modify-repo.sh"]
	}

	_repositories: {
		for f in input.frameworks {
			(f.name): {
				fillValues: bash.#Run & {
					input:   _deps.output
					workdir: "/workdir"
					env: {
						APP_NAME:     _args.vars.input.applicationName
						REPO_NAME:    _args.vars[(f.name)].repoName
						REPO_TYPE:    var.frameworkType[(f.name)]
						REPO_URL:     _args.vars[(f.name)].repoURL
						PROVIDER:     "github"
						ORGANIZATION: _args.vars.input.organization
					}
					mounts: kubeconfig: {
						dest:     "/root/.kube/config"
						contents: _args.kubeconfig
					}
					script: {
						directory: _modifyRepoSh.output
						filename:  "modify-repo.sh"
					}
					export: files: "/repository.yaml": _
				}
				write: apply.#File & {
					input: {
						kubeconfig: _args.kubeconfig
						contents:   fillValues.export.files."/repository.yaml"
					}
				}
			}
		}
	}

	_sh: core.#Source & {
		path: "."
		include: ["write-state.sh"]
	}

	_write: bash.#Run & {
		always:  true
		input:   _deps.output
		workdir: "/workdir"
		mounts: kubeconfig: {
			dest:     "/root/.kube/config"
			contents: _args.kubeconfig
		}
		script: {
			directory: _sh.output
			filename:  "write-state.sh"
		}
	}
}
