package micro

import (
	"github.com/h8r-dev/stacks/chain/v3/internal/base"
	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"universe.dagger.io/bash"
	"github.com/h8r-dev/stacks/chain/v3/component/ci"
	"github.com/h8r-dev/stacks/chain/v3/internal/var"
)

#Init: {
	input: {
		appName:      string
		organization: string
		githubToken:  dagger.#Secret
		kubeconfig:   dagger.#Secret
		vars:         var.#Generator
		services: [...]
	}
	_args: input

	_deps: base.#Image

	_sh: core.#Source & {
		path: "."
		include: ["micro.sh"]
	}

	for f in _args.services {
		(f.name): {
			_clone: bash.#Run & {
				always:  true
				input:   _deps.output
				workdir: "/workdir"
				env: {
					NAME:         f.name
					GIT_URL:      f.gitURL
					GITHUB_TOKEN: _args.githubToken
				}
				// mounts: kubeconfig: {
				//  dest:     "/root/.kube/config"
				//  contents: _args.kubeconfig
				// }
				script: {
					directory: _sh.output
					filename:  "micro.sh"
				}
			}
			_source: core.#Subdir & {
				input: _clone.output.rootfs
				path:  "/tmp/source"
			}
			_addWorkdflow: ci.#AddWorkflow & {
				input: {
					applicationName:  _args.appName
					organization:     _args.organization
					deployRepository: _args.vars.deploy.repoName
					sourceCode:       _source.output
				}
			}
		}
	}
}
