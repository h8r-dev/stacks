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
	output:      dagger.#FS & _evaluate.export.directories."/workdir"
	_template:   core.#Source & {
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
		language: "golang"
		setting:  _
		{
			isGenerated: false
			setting: {
				extension: {
					entryFile: string
					...
				}
				...
			}
		} | {
			isGenerated: true
			setting: {
				extention: {
					entryFile: "main.go"
					...
				}
				...
			}
		}
		_sh: core.#Source & {
			path: "."
			include: ["go.sh"]
		}
		_evaluate: bash.#Run & {
			input:   _deps.output
			workdir: "/workdir"
			script: {
				directory: _sh.output
				filename:  "go.sh"
			}
			export: directories: "/workdir": _
		}
		...
	} | {
		language: "typescript"
		_sh:      core.#Source & {
			path: "."
			include: ["ts.sh"]
		}
		_evaluate: bash.#Run & {
			input:   _deps.output
			workdir: "/workdir"
			script: {
				directory: _sh.output
				filename:  "ts.sh"
			}
			export: directories: "/workdir": _
		}
		...
	}
}
