package scaffold

import (
	"github.com/h8r-dev/chain/framework/gin"
	"github.com/h8r-dev/chain/framework/helm"
	"github.com/h8r-dev/chain/framework/next"
	"github.com/h8r-dev/chain/addons/loki"
	"github.com/h8r-dev/chain/addons/nocalhost"
	"github.com/h8r-dev/chain/addons/prometheus"
	nginxCloud "github.com/h8r-dev/chain/addons/ingress/nginx/cloud"
	nginxKind "github.com/h8r-dev/chain/addons/ingress/nginx/kind"
	// registry
	githubRegistry "github.com/h8r-dev/chain/registry/github"
	"github.com/h8r-dev/chain/ci/github"
	"github.com/h8r-dev/stacks/cuelib/utils/base"
	"universe.dagger.io/docker"
	"list"
)

#Instance: {

	framework: {
		"gin":  gin
		"helm": helm
		"next": next
	}

	addons: {
		"loki":                loki
		"prometheus":          prometheus
		"nocalhost":           nocalhost
		"ingress-nginx-cloud": nginxCloud
		"ingress-nginx-kind":  nginxKind
		// TODO FIX ME
		"ingress-nginx-minikube": nginxKind
	}

	ci: "github": github

	registry: github: githubRegistry

	input:                      #Input
	output:                     #Output
	_baseImage:                 base.#Image & {}
	_repositoryScaffoldImage:   docker.#Image
	_helmScaffoldImage:         docker.#Image
	_doCIScaffoldImage:         docker.#Image
	_helmRegistryScaffoldImage: docker.#Image

	frontendAndbackendScaffold: [ for t in input.repository if t.type != "deploy" {t}]
	helmScaffold: [ for t in input.repository if t.type == "deploy" {t}]

	// Do framework scaffold
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
				input: framework[i.framework].#Input & {
					name:  i.name
					image: _output
				}
			}
		}
	}

	if len(do) > 0 {
		_repositoryScaffoldImage: do["\(len(do)-1)"].output.image
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
				input: helm.#Input & {
					chartName: i.name
					image:     _output
					name:      helmScaffold[0].name
					if i.extraArgs.helmSet != _|_ {
						set: i.extraArgs.helmSet
					}
				}
			}
		}
	}

	if len(doHelmScaffold) > 0 {
		_helmScaffoldImage: doHelmScaffold["\(len(doHelmScaffold)-1)"].output.image
	}

	// Helm registry
	doHelmRegistryScaffold: {
		for idx, i in frontendAndbackendScaffold {
			"\(idx)": registry[i.registry].#Instance & {
				_output: docker.#Image
				if idx == 0 {
					_output: _helmScaffoldImage
				}
				if idx > 0 {
					_output: doHelmRegistryScaffold["\(idx-1)"].output.image
				}
				"input": registry[i.registry].#Input & {
					name:      i.name
					image:     _output
					chartName: helmScaffold[0].name
					username:  input.organization
					password:  input.personalAccessToken
				}
			}
		}
	}

	if len(doHelmScaffold) > 0 {
		_helmRegistryScaffoldImage: doHelmRegistryScaffold["\(len(doHelmRegistryScaffold)-1)"].output.image
	}

	// CI scaffold
	doCIScaffold: {
		for idx, i in frontendAndbackendScaffold {
			"\(idx)": ci[i.ci].#Instance & {
				_output: docker.#Image
				if idx == 0 {
					_output: _helmRegistryScaffoldImage
				}
				if idx > 0 {
					_output: doCIScaffold["\(idx-1)"].output.image
				}
				"input": ci[i.ci].#Input & {
					name:         i.name
					image:        _output
					organization: input.organization
					deployRepo:   helmScaffold[0].name
				}
			}
		}
	}

	if len(doCIScaffold) > 0 {
		_doCIScaffoldImage: doCIScaffold["\(len(doCIScaffold)-1)"].output.image
	}

	// should do latest
	exceptNginxIngressAddonsList: [ for t in input.addons if t.name != "ingress-nginx" {t}]
	ingressAddonsList: [ for t in input.addons if t.name == "ingress-nginx" {t}]
	conbineAddons: [...]

	if len(ingressAddonsList) > 0 {
		_ingressName: string
		if list.Contains(["kind", "minikube"], input.cloudProvider) {
			_ingressName: "ingress-nginx-" + input.cloudProvider
		}
		if !list.Contains(["kind", "minikube"], input.cloudProvider) {
			_ingressName: "ingress-nginx-cloud"
		}

		ingressAddons: [
			{
				name:    _ingressName
				version: ingressAddonsList[0].version
			},
		]
		conbineAddons: exceptNginxIngressAddonsList + ingressAddons
	}

	if len(ingressAddonsList) == 0 {
		conbineAddons: exceptNginxIngressAddonsList
	}
	// cue list for loop bug
	// https://github.com/cue-lang/cue/issues/798

	// fixAddonsList: [
	//  for t in input.addons {
	//   _name: string
	//   if t.name != "ingress-nginx" {
	//    _name: t.name
	//   }
	//   if t.name == "ingrsss-nginx" {
	//    _name: "ingrsss-nginx-kind"
	//    // if list.Contains(["kind", "minikube"], input.cloudProvider) {
	//    //  _name: t.name + "-" + input.cloudProvider
	//    // }
	//    // if !list.Contains(["kind", "minikube"], input.cloudProvider) {
	//    //  _name: t.name + "-" + "cloud"
	//    // }
	//    name: _name
	//   }
	//   name: _name
	//   if t.version != _|_ {
	//    version: t.version
	//   }
	//  },
	// ]

	doAddonsScaffold: {
		for idx, i in conbineAddons {
			"\(idx)": addons[i.name].#Instance & {
				_output: docker.#Image
				if idx == 0 {
					_output: _doCIScaffoldImage
				}
				if idx > 0 {
					_output: doAddonsScaffold["\(idx-1)"].output.image
				}
				input: addons[i.name].#Input & {
					helmName: helmScaffold[0].name
					image:    _output
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
