package github

import (
	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"universe.dagger.io/alpine"
	"universe.dagger.io/bash"
	"universe.dagger.io/docker"
)

#ManageRepo: {

	// Application name, will be set as repo name
	applicationName: string

	// Suffix
	suffix: *"" | string

	// Github personal access token, and will also use to pull ghcr.io image
	accessToken: dagger.#Secret

	// Github organization name or username
	organization: string

	// Source code path, for example code/go-gin
	sourceCodePath: string

	sourceCodeDir: dagger.#FS

	// Helm chart
	isHelmChart: string | *"false"

	// Repository visibility, default is private.
	repoVisibility: "public" | "private"

	terraformDir: "/terraform"

	kubeconfig: string | dagger.#Secret

	operationType: "init" | "delete"

	_loadTerraformFiles: core.#Source & {
		path: "./terraform"
		include: ["*.tf"]
	}

	base: docker.#Build & {
		steps: [
			alpine.#Build & {
				packages: {
					bash: {}
					git: {}
					jq: {}
					terraform: {}
					yq: {}
				}
			},
			docker.#Copy & {
				contents: sourceCodeDir
				dest:     "/root"
			},
			docker.#Copy & {
				contents: _loadTerraformFiles.output
				dest: 		terraformDir
			}
		]
	}

	_loadScripts: core.#Source & {
		path: "./scripts"
		include: ["*.sh"]
	}

	run: bash.#Run & {
		input: base.output
		export: files: "/create.json" : _
		workdir: "/root"
		always:  true
		mounts: {
			"kubeconfig": {
				dest: "/kubeconfig"
				contents: kubeconfig
			}
		}
		env: {
			GITHUB_TOKEN:     accessToken
			APPLICATION_NAME: applicationName
			SUFFIX:           suffix
			ORGANIZATION:     organization
			SOURCECODEPATH:   sourceCodePath
			ISHELMCHART:      isHelmChart
			REPO_VISIBILITY:  repoVisibility
			TERRAFORM_DIR:    terraformDir
			OUTPUT_FILE:      "/create.json"
			KUBE_CONFIG_PATH: "/kubeconfig"
			OPERATION_TYPE:   operationType
		}
		script: {
			directory: _loadScripts.output
			filename: "manage-repo.sh"
		}
	}

	readFile: core.#ReadFile & {
		input: run.output.rootfs
		path:  "/create.json"
	}

	url: readFile.contents
}
