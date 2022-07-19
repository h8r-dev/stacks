package test

import (
	"encoding/yaml"
	"dagger.io/dagger"
	"github.com/h8r-dev/stacks/chain/v4/pkg/k8s/kubectl"
	"github.com/h8r-dev/stacks/chain/v4/crd/forkmain"
	"github.com/h8r-dev/stacks/chain/v4/pkg/k8s/kubeconfig"

)

dagger.#Plan & {
	client: {
		commands: kubeconfig: {
			name: "cat"
			args: [env.KUBECONFIG]
			stdout: dagger.#Secret
		}
		env: KUBECONFIG: string
	}
	actions: {
		_transformKubeconfig: kubeconfig.#TransformToInternal & {
			input: kubeconfig: client.commands.kubeconfig.stdout
		}
		_kubeconfig: _transformKubeconfig.output.kubeconfig

		test: {
			args:         _
			kubeconfig:   _kubeconfig
			_application: kubectl.#Apply & {
				_app: forkmain.#Application & {
					input: {
						name:    args.application.name
						appName: args.application.name
					}
				}
				_contents: yaml.Marshal(_app.CRD)
				input: {
					"kubeconfig": kubeconfig
					contents:     _contents
				}
			}
			_environment: kubectl.#Apply & {
				_env: forkmain.#Environment & {
					input: {
						name:         args.application.name + "-main"
						envName:      args.application.name + "-main"
						appName:      args.application.name
						chartURL:     args.application.deploy.url
						chartPath:    args.application.name
						envAccessURL: args.application.domain
						envNamespace: args.application.name + "-production"
					}
				}
				_contents: yaml.Marshal(_env.CRD)
				input: {
					"kubeconfig": kubeconfig
					contents:     _contents
				}
			}
			_repo: {
				for s in args.application.service {
					(s.name): kubectl.#Apply & {
						_env: forkmain.#Repository & {
							input: {
								name:         args.application.name + "-" + s.name
								appName:      args.application.name
								repoName:     s.name
								repoURL:      s.repo.url
								organization: args.scm.organization
							}
						}
						_contents: yaml.Marshal(_env.CRD)
						input: {
							"kubeconfig": kubeconfig
							contents:     _contents
						}
					}
				}
			}
		}
	}
}
