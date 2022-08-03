package dockerfile

import (
	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"universe.dagger.io/bash"
	"universe.dagger.io/docker"
	"github.com/h8r-dev/stacks/chain/v5/internal/base"
)

#Generate: {
	isGenerated: bool
	type:        string
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
		type: "backend"
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
		type: "frontend-cmd"
		setting: {
			extension: {
				frontBuildCMD: string
				frontOutDir:   string
				frontRunCMD:   string
				...
			}
			...
		}
		_sh: core.#Source & {
			path: "."
			include: ["frontend-cmd.sh"]
		}
		_evaluate: bash.#Run & {
			input:   _deps.output
			workdir: "/workdir"
			env: {
				BUILD_CMD: setting.extension.frontBuildCMD
				OUT_DIR:   setting.extension.frontOutDir
				RUN_CMD:   setting.extension.frontRunCMD
			}
			script: {
				directory: _sh.output
				filename:  "frontend-cmd.sh"
			}
			export: directories: "/workdir": _
		}
		...
	} | {
		type: "frontend-static"
		setting: {
			extension: {
				frontBuildCMD: string
				frontOutDir:   string
				frontAppType:  string
				front404Path:  string
				...
			}
			...
		}
		_sh: core.#Source & {
			path: "."
			include: ["frontend-static.sh"]
		}
		_evaluate: bash.#Run & {
			input:   _deps.output
			workdir: "/workdir"
			env: {
				BUILD_CMD: setting.extension.frontBuildCMD
				OUT_DIR:   setting.extension.frontOutDir
				APP_TYPE:  setting.extension.frontAppType
				PATH404:   setting.extension.front404Path
			}
			script: {
				directory: _sh.output
				filename:  "frontend-static.sh"
			}
			export: directories: "/workdir": _
		}
	} | {
		type: "backend"
		language: name: "java"
		framework: "spring-boot"
		setting: {
			extension: {
				buildTool: string
				...
			}
			...
		}
		_buildTool: setting.extension.buildTool
		_sh:        core.#Source & {
			path: "."
			include: ["java.sh"]
		}
		_evaluate: bash.#Run & {
			input:   _deps.output
			workdir: "/workdir"
			env: {
				VERSION:    language.version
				BUILD_TOOL: _buildTool
			}
			script: {
				directory: _sh.output
				filename:  "java.sh"
			}
			export: directories: "/workdir": _
		}
	}
}
