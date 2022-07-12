package forkenv

import (
	"encoding/yaml"
	"dagger.io/dagger"
	"universe.dagger.io/bash"
	"universe.dagger.io/docker"
	"dagger.io/dagger/core"
	"github.com/h8r-dev/stacks/chain/v4/internal/base"
	utilsKubeconfig "github.com/h8r-dev/stacks/chain/v4/pkg/k8s/kubeconfig"
)

#Fork: {
	args: kubeconfig: dagger.#Secret

	// Need create env CRD for forkmain
	_transformKubeconfig: utilsKubeconfig.#TransformToInternal & {
		input: kubeconfig: args.kubeconfig
	}

	_kubeconfig: _transformKubeconfig.output.kubeconfig

	_addValuesFile: {
		for idx, f in args.service {
			"\(idx)": #AddValuesFileAndBranch & {
				_output: dagger.#FS | *null
				if idx > 0 {
					_output: _addValuesFile["\(idx-1)"].output.repo // use pre fs
				}
				input: {
					source:           _output
					repositoryName:   f.name
					repositoryType:   f.type
					repositoryUrl:    f.url
					deployRepository: args.deploy
					forkenv:          args.forkenv
					scm:              args.scm
					application:      args.application
					if f.env != _|_ {
						env: f.env
					}
				}
			}
		}
	}

	_addValuesFileFS: dagger.#FS

	if len(_addValuesFile) > 0 {
		_addValuesFileFS: _addValuesFile["\(len(_addValuesFile)-1)"].output.repo
	}

	_pushEnv: #PushEnv & {
		input: {
			source:           _addValuesFileFS
			appName:          args.application.name
			deployRepository: args.deploy
			forkenv:          args.forkenv
			scm:              args.scm
			kubeconfig:       _kubeconfig
		}
	}
}

#AddValuesFileAndBranch: {
	input: {
		source:           dagger.#FS | *null
		repositoryName:   string
		repositoryType:   string
		repositoryUrl:    string
		env:              _ | *null
		deployRepository: _
		forkenv:          _
		scm:              _
		application:      _
		gitUserName:      string | *"heighliner"
		gitUserEmail:     string | *"heighliner@h8r.dev"
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

	_write: output: dagger.#FS | *null

	if input.env != null {
		_yamlContents: yaml.Marshal(input.env)
		_write:        core.#WriteFile & {
			input:    dagger.#Scratch
			path:     "/env.yaml"
			contents: _yamlContents
		}
	}

	_writeYamlOutput: _write.output

	_sh: core.#Source & {
		path: "bash"
		include: ["add-values-file-and-env.sh"]
	}

	_push: bash.#Run & {
		"input": _deps.output
		workdir: "/workdir"
		env: {
			REPOSITORY_NAME:     input.repositoryName
			DEPLOY_URL:          input.deployRepository.url
			DEPLOY_NAME:         input.deployRepository.name
			GITHUB_TOKEN:        input.scm.token
			GITHUB_ORGANIZATION: input.scm.organization
			GIT_USER_NAME:       input.gitUserName
			GIT_USER_EMAIL:      input.gitUserEmail
			ENV_NAME:            input.forkenv.name
			DOMAIN:              input.forkenv.domain
			APP_NAME:            input.application.name
		}
		if input.env != null {
			mounts: yaml: core.#Mount & {
				contents: _writeYamlOutput
				source:   "/env.yaml"
				dest:     "/env.yaml"
			}
		}
		script: {
			directory: _sh.output
			filename:  "add-values-file-and-env.sh"
		}
		export: directories: "/workdir": _
	}

	output: repo: _push.export.directories."/workdir"
}

#PushEnv: {
	input: {
		source:           dagger.#FS | *null
		appName:          string
		deployRepository: _
		forkenv:          _
		scm:              _
		gitUserName:      string | *"heighliner"
		gitUserEmail:     string | *"heighliner@h8r.dev"
		kubeconfig:       dagger.#Secret
	}

	_envCRD: #EnvCRD & {
		"input": {
			envName:      input.forkenv.name
			appName:      input.appName
			namespace:    input.appName + "-" + input.forkenv.name
			chartUrl:     input.deployRepository.url
			envPath:      "env/" + input.forkenv.name
			envAccessUrl: input.forkenv.domain
		}
	}

	_yamlContents: yaml.Marshal(_envCRD.CRD)

	_write: core.#WriteFile & {
		input:    dagger.#Scratch
		path:     "/env.yaml"
		contents: _yamlContents
	}

	_deps: docker.#Build & {
		steps: [
			base.#Image,
			docker.#Copy & {
				contents: input.source
				dest:     "/helm"
			},
		]
	}

	_sh: core.#Source & {
		path: "bash"
		include: ["push-env.sh"]
	}

	_run: bash.#Run & {
		env: {
			GITHUB_TOKEN:        input.scm.token
			GITHUB_ORGANIZATION: input.scm.organization
			GIT_USER_NAME:       input.gitUserName
			GIT_USER_EMAIL:      input.gitUserEmail
			ENV_NAME:            input.forkenv.name
			APP_NAME:            input.appName
			KUBECONFIG:          "/kubeconfig"
		}
		"input": _deps.output
		workdir: "/helm"
		script: {
			directory: _sh.output
			filename:  "push-env.sh"
		}
		mounts: yaml: core.#Mount & {
			contents: _write.output
			source:   "/env.yaml"
			dest:     "/crd/env.yaml"
		}
		mounts: kubeconfig: {
			dest:     "/kubeconfig"
			contents: input.kubeconfig
			mask:     0o022
		}
	}

	success: _run.success
}

#EnvCRD: {
	input: {
		envName:      string
		appName:      string
		namespace:    string
		chartUrl:     string
		envPath:      string
		envAccessUrl: string
	}
	CRD: {
		apiVersion: "cloud.heighliner.dev/v1alpha1"
		kind:       "Environment"
		metadata: {
			// env name with no prefix
			name: input.envName
			// application name
			labels: "app.heighliner.dev/name": input.appName
		}
		spec: {
			// env name with prefix
			name:      input.appName + "-" + input.envName
			namespace: input.namespace
			chart: {
				// default version
				version: "0.0.1"
				// chart git url
				url:  input.chartUrl
				type: "github"
				// env path
				path: input.envPath
				// default value
				valuesFile:    "values.yaml"
				defaultBranch: "main"
			}
			// access url
			access: previewURL: input.envAccessUrl
		}
	}
}
