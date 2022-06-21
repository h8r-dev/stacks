package template

import (
	"dagger.io/dagger"
	"github.com/h8r-dev/stacks/chain/internal/utils/fs"
	"universe.dagger.io/alpine"
	"universe.dagger.io/bash"
	"universe.dagger.io/docker"
)

#RenderDir: {
	// data yaml for template
	yamlData: string
	// template files Dir
	inputDir: dagger.#FS
	// subpath for template files to render
	path: string

	base: alpine.#Build & {
		packages: {
			bash: {}
			gomplate: {}
		}
	}

	run: docker.#Build & {
		steps: [
			fs.#WriteFile & {
				input:    base.output
				contents: yamlData
				path:     "/gomplate-data.yaml"
			},
			bash.#Run & {
				workdir: "/root"
				always:  true
				env: INPUT_PATH: path

				mounts: "inputDir": {
					dest:     "/input-dirs"
					contents: inputDir
				}

				script: contents: #"""
					gomplate --input-dir /input-dirs/$INPUT_PATH --output-dir /output -c .=/gomplate-data.yaml?type=application/yaml
					"""#
			},
		]
	}

	// Get renderd output in /output dir
	output: run.output.rootfs
}
