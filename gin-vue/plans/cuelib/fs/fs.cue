package fs

import(
    "universe.dagger.io/docker"
    "dagger.io/dagger"
)

// Build step that copies files into the container image
#WriteFile: {
	input:       docker.#Image
	contents:    string
	path:        string | *"/"
	permissions: *0o600 | int

	// Execute write operation
	_copy: dagger.#WriteFile & {
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