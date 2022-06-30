package terraform

import (
	"universe.dagger.io/bash"
	"github.com/h8r-dev/stacks/chain/internal/utils/base"
)

#Instance: {
	input:  #Input
	_image: base.#Image
	run:    bash.#Run & {
		mounts: "/terraform": {
			dest:     "/terraform"
			contents: input.source
		}
		workdir: "/terraform"
		always:  true
		env:     input.env
		"input": _image.output
		script: contents: #"""
				terraform init
				terraform apply -auto-approve
				mkdir -p /output
				terraform output -json > /output/output.json
			"""#
		export: files: "/output/output.json": string
	}
	content: run.export.files."/output/output.json"
	output:  #Output & {
		image: run.output
	}
}
