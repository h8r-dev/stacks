package terraform

import (
	"dagger.io/dagger"
)

#Input: {
	// Terraform plans file
	source: dagger.#FS

	// Terraform running environment, should prefix with "TF_VAR_" 
	env: [string]: string
}
