package dockerfile

import (
	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"universe.dagger.io/bash"
	"universe.dagger.io/docker"
	"github.com/h8r-dev/stacks/chain/v4/internal/base"
)

#Generate: {
	isGenerated: bool
	language: {
		name:    string
		version: string
	}
	framework: string
	output:    dagger.#FS & _evaluate.export.directories."/workdir"
	_template: core.#Source & {
		path: "template"
	}
	_deps: docker.#Build & {
		steps: [
			base.#Image,
			docker.#Copy & {
				contents: _template.output
				dest:     "/source"
			},
		]
	}
	_evaluate: {
		export: directories: "/workdir": _
		...
	}
	{
		language: {
			name:    "golang"
			version: string | *"1.18"
		}
		framework:  "gin"
		_entryFile: string
		setting:    _
		{
			isGenerated: false
			setting: {
				extension: {
					entryFile: string | *"/"
					...
				}
				...
			}
			_entryFile: setting.extension.entryFile
		} | {
			isGenerated: true
			_entryFile:  "/"
		}
		_sh: core.#Source & {
			path: "."
			include: ["gin.sh"]
		}
		_evaluate: bash.#Run & {
			input:   _deps.output
			workdir: "/workdir"
			env: {
				VERSION:    language.version
				ENTRY_FILE: _entryFile
			}
			script: {
				directory: _sh.output
				filename:  "gin.sh"
			}
			export: directories: "/workdir": _
		}
		...
	} | {
		language: name: "typescript"
		framework: "nextjs"
		_sh:       core.#Source & {
			path: "."
			include: ["nextjs.sh"]
		}
		_evaluate: bash.#Run & {
			input:   _deps.output
			workdir: "/workdir"
			script: {
				directory: _sh.output
				filename:  "nextjs.sh"
			}
			export: directories: "/workdir": _
		}
		...
	}
}
