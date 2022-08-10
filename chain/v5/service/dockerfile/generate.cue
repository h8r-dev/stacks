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
		framework: "gin"
		setting: {
			extension: {
				goBuildCMD: string
				goRunCMD:   string
				...
			}
			...
		}
		{
			isGenerated: false
			setting: {
				extension: {
					goBuildCMD: string
					goRunCMD:   string
					...
				}
				...
			}
		} | {
			isGenerated: true
			setting: {
				extension: {
					goBuildCMD: string | "go build -o ./app main.go"
					goRunCMD:   string | "./app"
					...
				}
				...
			}
		}
		_sh: core.#Source & {
			path: "."
			include: ["gin.sh"]
		}
		_evaluate: bash.#Run & {
			input:   _deps.output
			workdir: "/workdir"
			env: {
				VERSION:   language.version
				BUILD_CMD: setting.extension.goBuildCMD
				RUN_CMD:   setting.extension.goRunCMD
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
				frontendBuildCMD: string
				frontendOutDir:   string
				frontendRunCMD:   string
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
				BUILD_CMD: setting.extension.frontendBuildCMD
				OUT_DIR:   setting.extension.frontendOutDir
				RUN_CMD:   setting.extension.frontendRunCMD
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
				frontendBuildCMD: string
				frontendOutDir:   string
				frontendAppType:  string
				frontend404Path:  string
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
				BUILD_CMD: setting.extension.frontendBuildCMD
				OUT_DIR:   setting.extension.frontendOutDir
				APP_TYPE:  setting.extension.frontendAppType
				PATH404:   setting.extension.frontend404Path
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
