package fs

import (
	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"universe.dagger.io/alpine"
	"github.com/h8r-dev/stacks/cuelib/utils/fs"
)

dagger.#Plan & {
	actions: {
		baseImage: alpine.#Build & {
		}

		write: fs.#WriteFile & {
			input:    baseImage.output
			path:     "/test.txt"
			contents: "foo-bar"
		}

		test: core.#ReadFile & {
			input: write.output.rootfs
			path:  "/test.txt"
		} & {
			contents: "foo-bar"
		}
	}
}
