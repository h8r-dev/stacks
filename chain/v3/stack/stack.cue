package stack

import (
	"dagger.io/dagger"
	"github.com/h8r-dev/stacks/chain/v3/component/deploy"
	"github.com/h8r-dev/stacks/chain/v3/component/repository"
	"github.com/h8r-dev/stacks/chain/v3/internal/addon"
	utilsKubeconfig "github.com/h8r-dev/stacks/chain/v3/internal/utils/kubeconfig"
	"github.com/h8r-dev/stacks/chain/v3/internal/var"
)

#Install: {
	args: {
		name:           string
		domain:         string
		networkType:    string
		repoVisibility: string
		organization:   string
		githubToken:    dagger.#Secret
		kubeconfig:     dagger.#Secret
		frameworks: [...]
		addons: [...]
		initRepos: string | *"true"
		services: [...]
	}

	_var: var.#Generator & {
		input: {
			applicationName: args.name
			domain:          args.domain
			networkType:     args.networkType
			organization:    args.organization
			frameworks:      args.frameworks
			addons:          args.addons
			services:        args.services
		}
	}

	_transformKubeconfig: utilsKubeconfig.#TransformToInternal & {
		input: kubeconfig: args.kubeconfig
	}

	_infra: addon.#ReadInfraConfig & {
		input: kubeconfig: _transformKubeconfig.output.kubeconfig
	}

	_createRepos: repository.#Create & {
		input: {
			initRepos:       args.initRepos
			appName:         args.name
			scmOrganization: args.organization
			repoVisibility:  args.repoVisibility
			githubToken:     args.githubToken
			kubeconfig:      _transformKubeconfig.output.kubeconfig
			vars:            _var
			frameworks:      args.frameworks
			services:        args.services
		}
	}

	_deployApp: deploy.#Init & {
		input: {
			name:           args.name
			domain:         args.domain
			repoVisibility: args.repoVisibility
			organization:   args.organization
			githubToken:    args.githubToken
			kubeconfig:     _transformKubeconfig.output.kubeconfig
			frameworks:     args.frameworks
			services:       args.services
			vars:           _var
			cdVar:          _infra.argoCD
			waitFor:        _createRepos.output.success
		}
	}

	// _config: {
	//  for f in args.frameworks {
	//   (f.name): framework.#Config & {
	//    name:   f.name
	//    addons: args.addons
	//   }
	//  }
	// }
}
