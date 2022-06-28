package env

import (
	"dagger.io/dagger"
	"github.com/h8r-dev/stacks/chain/v3/internal/var"
	"strconv"
	"universe.dagger.io/bash"
	"universe.dagger.io/docker"
	"dagger.io/dagger/core"
	"github.com/h8r-dev/stacks/chain/v3/internal/base"
)

#Create: {
	input: {
		envName:         string
		appName:         string
		scmOrganization: string
		githubToken:     dagger.#Secret
		vars:            var.#Generator
		domain:          string
		frameworks: [...]
		waitFor:      bool | *true
		gitUserName:  string | *"heighliner"
		gitUserEmail: string | *"heighliner@h8r.dev"
		kubeconfig:   dagger.#Secret
	}

	_args: input

	_addValuesFile: {
		for idx, f in input.frameworks {
			"\(idx)": #AddValuesFile & {
				_output: dagger.#FS | *null
				if idx > 0 {
					_output: _addValuesFile["\(idx-1)"].output.repo // use pre fs
				}
				input: {
					repositoryName:      _args.vars[(f.name)].repoName
					personalAccessToken: _args.githubToken
					organization:        _args.scmOrganization
					source:              _output
					applicationName:     _args.appName
					envName:             _args.envName
					domain:              _args.domain
					waitFor:             _args.waitFor
				}
			}
		}
	}

	_addValuesFileFS: dagger.#FS

	if len(_addValuesFile) > 0 {
		_addValuesFileFS: _addValuesFile["\(len(_addValuesFile)-1)"].output.repo
	}

	_template: core.#Source & {
		path: "template"
		include: ["*.yaml"]
	}

	_deps: docker.#Build & {
		steps: [
			base.#Image,
			docker.#Copy & {
				contents: _addValuesFileFS
				dest:     "/helm"
			},
			docker.#Copy & {
				contents: _template.output
				dest:     "/argoappset"
			},
		]
	}

	_sh: core.#Source & {
		path: "."
		include: ["push-env.sh"]
	}

	_run: bash.#Run & {
		env: {
			WAIT_FOR:            strconv.FormatBool(_args.waitFor)
			GITHUB_TOKEN:        _args.githubToken
			GIT_USER_NAME:       _args.gitUserName
			GIT_USER_EMAIL:      _args.gitUserEmail
			ENV_NAME:            _args.envName
			GITHUB_ORGANIZATION: _args.scmOrganization
			APP_NAME:            _args.appName
			KUBECONFIG:          "/kubeconfig"
		}
		mounts: kubeconfig: {
			dest:     "/kubeconfig"
			contents: input.kubeconfig
			mask:     0o022
		}
		"input": _deps.output
		workdir: "/helm"
		script: {
			directory: _sh.output
			filename:  "push-env.sh"
		}
		//export: directories: "/helm": _
	}
	//output: chart: _run.export.directories."/helm"
}

#AddValuesFile: {
	input: {
		source:              dagger.#FS | *null
		applicationName:     string
		repositoryName:      string
		personalAccessToken: dagger.#Secret
		organization:        string
		envName:             string
		gitUserName:         string | *"heighliner"
		gitUserEmail:        string | *"heighliner@h8r.dev"
		domain:              string
		waitFor:             bool
	}

	_deps: docker.#Build & {
		steps: [
			base.#Image,
			if input.source != null {
				docker.#Copy & {
					contents: input.source
					dest:     "/workdir"
				}
			},
		]
	}

	_sh: core.#Source & {
		path: "."
		include: ["add-values-file.sh"]
	}

	_push: bash.#Run & {
		"input": _deps.output
		workdir: "/workdir"
		env: {
			WAIT_FOR:            strconv.FormatBool(input.waitFor)
			REPOSITORY_NAME:     input.repositoryName
			APP_NAME:            input.applicationName
			GITHUB_TOKEN:        input.personalAccessToken
			GITHUB_ORGANIZATION: input.organization
			GIT_USER_NAME:       input.gitUserName
			GIT_USER_EMAIL:      input.gitUserEmail
			ENV_NAME:            input.envName
			DOMAIN:              input.domain
		}
		script: {
			directory: _sh.output
			filename:  "add-values-file.sh"
		}
		export: directories: "/workdir": _
	}

	output: repo: _push.export.directories."/workdir"
}
