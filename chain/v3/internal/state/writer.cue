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
		domain:     string
		kubeconfig: dagger.#Secret
		frameworks: [...]
		vars:      var.#Generator
		namespace: string | *"heighliner"
		waitFor:   bool | *true
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
						NAMESPACE:    "\(_args.namespace)"
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

		// TODO conmibe this with frameworks
		deploy: {
			fillValues: bash.#Run & {
				input:   _deps.output
				workdir: "/workdir"
				env: {
					APP_NAME:     _args.vars.input.applicationName
					NAMESPACE:    "\(_args.namespace)"
					REPO_NAME:    _args.vars.deploy.repoName
					REPO_TYPE:    "deploy"
					REPO_URL:     _args.vars.deploy.repoURL
					PROVIDER:     "github"
					ORGANIZATION: _args.vars.input.organization
					WAIT_FOR:     "\(_args.waitFor)"
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

	_modifyAppSh: core.#Source & {
		path: "."
		include: ["modify-app.sh"]
	}

	_application: {
		fillValues: bash.#Run & {
			input:   _deps.output
			workdir: "/workdir"
			env: {
				APP_NAME:      _args.vars.input.applicationName
				NAMESPACE:     "\(_args.namespace)"
				STACK_NAME:    "gin-next"
				STACK_VERSION: "0.0.1"
				WAIT_FOR:      "\(_args.waitFor)"
			}
			script: {
				directory: _modifyAppSh.output
				filename:  "modify-app.sh"
			}
			export: files: "/application.yaml": _
		}
		write: apply.#File & {
			input: {
				kubeconfig: _args.kubeconfig
				contents:   fillValues.export.files."/application.yaml"
			}
		}
	}

	_modifyEnvSh: core.#Source & {
		path: "."
		include: ["modify-env.sh"]
	}

	_environment: {
		fillValues: bash.#Run & {
			input:   _deps.output
			workdir: "/workdir"
			env: {
				APP_NAME:             _args.vars.input.applicationName
				NAMESPACE:            "\(_args.namespace)"
				DEVSPACE_NAME:        "dev"
				DEVSPACE_NAMEPSACE:   "dev"
				PREVIEW_URL:          "http://dev." + _args.vars.input.applicationName + "." + _args.domain
				CHART_VERSION:        "0.0.1"
				CHART_URL:            _args.vars.deploy.repoURL
				CHART_TYPE:           "github"
				CHART_PATH:           "/" + _args.vars.input.applicationName
				CHART_VALUES_FILE:    "values.yaml"
				CHART_DEFAULT_BRANCH: "main"
				WAIT_FOR:             "\(_args.waitFor)"
			}
			script: {
				directory: _modifyEnvSh.output
				filename:  "modify-env.sh"
			}
			export: files: "/environment.yaml": _
		}
		write: apply.#File & {
			input: {
				kubeconfig: _args.kubeconfig
				contents:   fillValues.export.files."/environment.yaml"
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
