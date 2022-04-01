package nocalhost

import (
	"dagger.io/dagger"
	"universe.dagger.io/bash"
	"github.com/h8r-dev/gin-vue/plans/cuelib/nocalhost"
	"github.com/h8r-dev/gin-vue/plans/cuelib/random"
	"github.com/h8r-dev/gin-vue/plans/cuelib/ingress"
	"github.com/h8r-dev/gin-vue/plans/cuelib/kubectl"
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
		uri:         random.#String
		infraDomain: ".stack.h8r.io"
		_kubectl:    kubectl.#Kubectl
		// get ingress endpoint
		getIngressEndPoint: ingress.#GetIngressEndpoint & {
			kubeconfig: client.commands.kubeconfig.stdout
		}

		getIngressVersion: bash.#Run & {
			input:   _kubectl.output
			workdir: "/src"
			mounts: "KubeConfig Data": {
				dest:     "/kubeconfig"
				contents: client.commands.kubeconfig.stdout
			}
			script: contents: #"""
				ingress_result=$(kubectl --kubeconfig /kubeconfig api-resources --api-group=networking.k8s.io)
				if [[ $ingress_result =~ "v1beta1" ]]; then
				 echo 'v1beta1' > /result
				else
				 echo 'v1' > /result
				fi
				"""#
			export: files: "/result": string
		}

		test: {
			initNocalhost: nocalhost.#InitData & {
				url:                "http://\(uri.output).nocalhost.stack.h8r.io"
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
				ingressVersion: getIngressVersion.export.files."/result"
				domain:         uri.output + ".nocalhost" + infraDomain
				host:           getIngressEndPoint.endPoint
				namespace:      "nocalhost"
				name:           "nocalhost"
			}
		}
	}
}
