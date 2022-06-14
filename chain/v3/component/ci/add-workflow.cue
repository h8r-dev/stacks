package ci

import (
	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"universe.dagger.io/bash"
	"universe.dagger.io/docker"

	"github.com/h8r-dev/stacks/chain/v3/internal/base"
)

#AddWorkflow: {
	input: {
		applicationName:  string
		organization:     string
		deployRepository: string
		sourceCode:       dagger.#FS
	}

	output: sourceCode: _do.export.directories."/workdir/source"

	_loadWorkflows: core.#Source & {
		path: "./template"
		include: ["*.yaml"]
	}

	_sourceCodeDir: "/workdir/source"
	_workflowDir:   "/workdir/workflows"

	_deps: docker.#Build & {
		steps: [
			base.#Image,
			docker.#Copy & {
				contents: input.sourceCode
				dest:     _sourceCodeDir
			},
			docker.#Copy & {
				contents: _loadWorkflows.output
				dest:     _workflowDir
			},
		]
	}

	_sh: core.#Source & {
		path: "."
		include: ["add-workflow.sh"]
	}

	_args: {
		organization:     input.organization
		applicationName:  input.applicationName
		deployRepository: input.deployRepository
	}

	_do: bash.#Run & {
		always:  true
		input:   _deps.output
		workdir: "/workdir"
		env: {
			SOURCE_CODE_DIR: _sourceCodeDir
			WORKFLOW_SRC:    _workflowDir
			ORGANIZATION:    _args.organization
			APP_NAME:        _args.applicationName
			HELM_REPO:       _args.deployRepository
		}
		script: {
			directory: _sh.output
			filename:  "add-workflow.sh"
		}
		export: directories: "/workdir/source": _
	}
}
