package scaffold

import (
	"github.com/h8r-dev/chain/framework/gin"
	"github.com/h8r-dev/chain/framework/helm"
	"github.com/h8r-dev/chain/framework/next"
	"github.com/h8r-dev/chain/addons/loki"
	"github.com/h8r-dev/chain/addons/nocalhost"
	"github.com/h8r-dev/chain/addons/prometheus"
	"github.com/h8r-dev/cuelib/utils/base"
	"universe.dagger.io/docker"
)

#Instance: {
	framework: {
		"gin":  gin
		"helm": helm
		"next": next
	}
	addons: {
		"loki":       loki
		"prometheus": prometheus
		"nocalhost":  nocalhost
	}
	input:                    #Input
	output:                   #Output
	_baseImage:               base.#Image & {}
	_repositoryScaffoldImage: docker.#Image
	_helmScaffoldImage:       docker.#Image
	frontendAndbackendScaffold: [ for t in input.repository if t.type != "deploy" {t}]
	helmScaffold: [ for t in input.repository if t.type == "deploy" {t}]
	do: {
		for idx, i in frontendAndbackendScaffold {
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
		_repositoryScaffoldImage: do["\(len(do)-1)"].output.image
		// output: #Output & {
		//  image: do["\(len(do)-1)"].output.image
		// }
	}

	doHelmScaffold: {
		for idx, i in frontendAndbackendScaffold {
			"\(idx)": helm.#Instance & {
				_output: docker.#Image
				if idx == 0 {
					_output: _repositoryScaffoldImage
				}
				if idx > 0 {
					_output: doHelmScaffold["\(idx-1)"].output.image
				}
				"input": helm.#Input & {
					"chartName": i.name
					"image":     _output
					"name":      helmScaffold[0].name
				}
			}
		}
	}

	if len(doHelmScaffold) > 0 {
		_helmScaffoldImage: doHelmScaffold["\(len(doHelmScaffold)-1)"].output.image
		// output: #Output & {
		//  image: doHelmScaffold["\(len(doHelmScaffold)-1)"].output.image
		// }
	}

	doAddonsScaffold: {
		for idx, i in input.addons {
			"\(idx)": addons[i.name].#Instance & {
				_output: docker.#Image
				if idx == 0 {
					_output: _helmScaffoldImage
				}
				if idx > 0 {
					_output: doAddonsScaffold["\(idx-1)"].output.image
				}
				"input": addons[i.name].#Input & {
					"helmName": helmScaffold[0].name
					"image":    _output
				}
			}
		}
	}

	if len(doAddonsScaffold) > 0 {
		output: #Output & {
			image: doAddonsScaffold["\(len(doAddonsScaffold)-1)"].output.image
		}
	}
}
