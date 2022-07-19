package update

import (
	"encoding/yaml"
	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"universe.dagger.io/bash"
	"universe.dagger.io/docker"
	"github.com/h8r-dev/stacks/chain/v4/deploy/chart"
	"github.com/h8r-dev/stacks/chain/v4/internal/base"
)

#Run: {
	args: _
	_set: {
		for idx, s in args.application.service {
			"\(idx)": #Update & {
				if idx > 0 {
					_output: _set["\(idx-1)"].output
					repo:    _output
					first:   false
				}
				if (idx + 1) == len(args.application.service) {
					end: true
				}

				if len(s.setting.expose) > 0 {
					_expose:  s.setting.expose[0]
					_ingress: chart.#Ingress & {
						input: {
							rewrite: _expose.rewrite
							host:    args.application.domain
							paths:   _expose.paths
						}
					}
					ingressValue: yaml.Marshal(_ingress.info)
				}
				deploymentEnv: yaml.Marshal(s.setting.env)
				valuePath:     args.application.name + "/values.yaml"
				serviceName:   s.name
				repoURL:       args.application.deploy.url
				repoToken:     args.internal.githubToken
			}
		}
	}
}

#Update: {
	repoURL:       string
	repoToken:     dagger.#Secret
	repo?:         dagger.#FS
	valuePath:     string
	serviceName:   string
	deploymentEnv: string | *""
	ingressValue:  string | *""
	end:           bool | *false
	first:         bool | *true

	_deps: docker.#Build & {
		steps: [
			base.#Image,
			if repo != _|_ {
				docker.#Copy & {
					contents: repo
					dest:     "/deploy"
				}
			},

		]
	}

	_sh: core.#Source & {
		path: "."
		include: ["update.sh"]
	}

	_run: bash.#Run & {
		input:   _deps.output
		always:  true
		workdir: "/deploy"
		env: {
			NAME:           serviceName
			DEPLOYMENT_ENV: deploymentEnv
			INGRESS_VALUE:  ingressValue
			VALUE_PATH:     valuePath
			END:            "\(end)"
			REPO_URL:       repoURL
			TOKEN:          repoToken
			FIRST:          "\(first)"
		}
		script: {
			directory: _sh.output
			filename:  "update.sh"
		}
		export: directories: "/deploy": _
	}

	output: _run.export.directories."/deploy"
}
