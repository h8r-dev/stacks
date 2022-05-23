package github

import (
	"universe.dagger.io/docker"
	"universe.dagger.io/bash"
	"dagger.io/dagger/core"
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
			TEMPLATE_DIR: templateDir
		}
		script: {
			directory: _loadScripts.output
			filename:  "create.sh"
		}
	}

	output: #Output & {
		image: do.output
	}
}
