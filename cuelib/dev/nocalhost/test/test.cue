package nocalhost

import (
	"dagger.io/dagger"
	"github.com/h8r-dev/cuelib/dev/nocalhost"
	"github.com/h8r-dev/cuelib/utils/random"
	"github.com/h8r-dev/cuelib/network/ingress"
	"github.com/h8r-dev/cuelib/deploy/helm"
	"github.com/h8r-dev/cuelib/deploy/kubectl"
)

ingressNginxSetting: #"""
	controller:
	  service:
	    type: LoadBalancer
	  metrics:
	    enabled: true
	  podAnnotations:
	    prometheus.io/scrape: "true"
	    prometheus.io/port: "10254"
	"""#

uri:          random.#String
infraDomain:  ".stack.h8r.io"
nocalhostURL: uri.output + ".nocalhost" + infraDomain

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
		getIngressEndPoint: ingress.#GetIngressEndpoint & {
			kubeconfig: client.commands.kubeconfig.stdout
		}

		getIngressVersion: ingress.#GetIngressVersion & {
			kubeconfig: client.commands.kubeconfig.stdout
		}

		installIngress: helm.#Chart & {
			name:       "ingress-nginx"
			repository: "https://h8r-helm.pkg.coding.net/release/helm"
			chart:      "ingress-nginx"
			namespace:  "ingress-nginx"
			action:     "installOrUpgrade"
			kubeconfig: client.commands.kubeconfig.stdout
			values:     ingressNginxSetting
			wait:       true
		}

		test: {
			initNocalhost: nocalhost.#InitData & {
				url:                nocalhostURL
				githubAccessToken:  client.env.GITHUB_TOKEN
				githubOrganization: client.env.ORGANIZATION
				kubeconfig:         client.commands.kubeconfig.stdout
				appName:            client.env.APP_NAME
				appGitURL:          "https://github.com/just-a-test/test"
				waitFor:            installNocalhost.success
			}

			// installNocalhost: your can wait this action by installNocalhost.success
			installNocalhost: nocalhost.#Install & {
				"uri":          "just-test" + uri.output
				kubeconfig:     client.commands.kubeconfig.stdout
				ingressVersion: getIngressVersion.content
				domain:         nocalhostURL
				host:           getIngressEndPoint.content
				namespace:      "nocalhost"
				name:           "nocalhost"
				waitFor:        installIngress.success
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
