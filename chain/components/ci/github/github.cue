package github

import (
	"dagger.io/dagger/core"
	"universe.dagger.io/bash"
	"universe.dagger.io/docker"
)

#Instance: {
	input: #Input

	_loadTemplates: core.#Source & {
		path: "./template"
		include: ["*.yaml"]
	}

	_loadScripts: core.#Source & {
		path: "."
		include: ["*.sh"]
	}

	templateDir: "/h8r/ci/\(input.name)/templates"

	copy_templates: docker.#Copy & {
		"input":  input.image
		contents: _loadTemplates.output
		dest:     templateDir
	}

	do: bash.#Run & {
		"input": copy_templates.output
		env: {
			REPO_NAME:    input.name
			ORGANIZATION: input.organization
			APP_NAME:     input.appName
			HELM_REPO:    input.deployRepo
			TEMPLATE_DIR: templateDir
		}
		script: {
			directory: _loadScripts.output
			filename:  "create-workflow.sh"
		}
	}

	output: #Output & {
		image: do.output
	}
}
