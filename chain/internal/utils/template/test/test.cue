package gomplate

import (
	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"github.com/h8r-dev/stacks/chain/internal/utils/template"
	"encoding/yaml"
)

// for test
dagger.#Plan & {

	actions: {
		write: core.#WriteFile & {
			input:    dagger.#Scratch
			contents: "{{ .abc }} hello"
			path:     "/abcde.txt"
		}
		test: template.#RenderDir & {
			yamlData: yaml.Marshal({
				abc: "hello world"
				bcd: "Heighliner"
			})
			inputDir: write.output
			path:     ""
		}
	}
}
