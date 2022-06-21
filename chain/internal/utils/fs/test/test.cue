package fs

import (
	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"github.com/h8r-dev/stacks/chain/internal/utils/fs"
	"universe.dagger.io/alpine"
)

dagger.#Plan & {
	actions: {
		baseImage: alpine.#Build & {
		}

		write: fs.#WriteFile & {
			input:       baseImage.output
			permissions: 0o644
			path:        "/test.txt"
			contents:    "foo-bar"
		}

		test: core.#ReadFile & {
			input: write.output.rootfs
			path:  "/test.txt"
		} & {
			contents: "foo-bar"
		}
	}
}
