package nocalhost

import (
	"dagger.io/dagger"
	"github.com/h8r-dev/stacks/chain/internal/dev/nocalhost"
	"github.com/h8r-dev/stacks/chain/internal/network/ingress"
	"github.com/h8r-dev/stacks/chain/internal/deploy/kubectl"
)

dagger.#Plan & {
	client: {
		commands: kubeconfig: {
			name: "cat"
			args: ["\(env.KUBECONFIG)"]
			stdout: dagger.#Secret
		}
		env: {
			KUBECONFIG:   string
			ORGANIZATION: string
			GITHUB_TOKEN: dagger.#Secret
			APP_NAME:     string
		}
	}

	actions: {
		getIngressVersion: ingress.#GetIngressVersion & {
			kubeconfig: client.commands.kubeconfig.stdout
		}

		test: {
			initNocalhost: nocalhost.#InitData & {
				githubAccessToken:  client.env.GITHUB_TOKEN
				githubOrganization: client.env.ORGANIZATION
				kubeconfig:         client.commands.kubeconfig.stdout
				appName:            client.env.APP_NAME
				appGitURL:          "https://github.com/just-a-test/test"
				waitFor:            installNocalhost.success
			}

			// installNocalhost: your can wait this action by installNocalhost.success
			installNocalhost: nocalhost.#Install & {
				uri:            "just-test"
				kubeconfig:     client.commands.kubeconfig.stdout
				ingressVersion: getIngressVersion.content
				domain:         "nocalhost.127-0-0-1.nip.io"
				namespace:      "nocalhost"
				name:           "nocalhost"
				chartVersion:   "0.6.16"
			}

			createImagePullSecretForDevNs: kubectl.#CreateImagePullSecret & {
				kubeconfig: client.commands.kubeconfig.stdout
				username:   client.env.ORGANIZATION
				password:   client.env.GITHUB_TOKEN
				namespace:  initNocalhost.nsOutput
			}
		}
	}
}
