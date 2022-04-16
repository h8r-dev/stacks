package scaffold

import (
	"github.com/h8r-dev/chain/framework/gin"
	"github.com/h8r-dev/chain/framework/helm"
	"github.com/h8r-dev/chain/framework/next"
	"github.com/h8r-dev/cuelib/utils/base"
	"universe.dagger.io/docker"
)

#Instance: {
	framework: {
		"gin":  gin
		"helm": helm
		"next": next
	}
	input:      #Input
	output:     #Output
	_baseImage: base.#Image & {}
	do: {
		for idx, i in input.repository {
			"\(idx)": framework[i.framework].#Instance & {
				_output: docker.#Image
				if idx == 0 {
					_output: _baseImage.output
				}
				if idx > 0 {
					_output: do["\(idx-1)"].output.image
				}
				"input": framework[i.framework].#Input & {
					"name":  i.name
					"image": _output
				}
			}
		}
	}

	if len(do) > 0 {
		output: #Output & {
			image: do["\(len(do)-1)"].output.image
		}
	}
}
