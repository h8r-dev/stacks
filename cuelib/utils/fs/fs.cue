package fs

import (
	"dagger.io/dagger/core"
	"universe.dagger.io/docker"
)

// Build step that copies files into the container image
#WriteFile: {
	input:       docker.#Image
	contents:    string
	path:        string | *"/"
	permissions: *0o600 | int

	// Execute write operation
	_copy: core.#WriteFile & {
		"input":       input.rootfs
		"contents":    contents
		"path":        path
		"permissions": permissions
	}

	output: docker.#Image & {
		config: input.config
		rootfs: _copy.output
	}
}
