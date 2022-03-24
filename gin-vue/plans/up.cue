package main

import (
	"dagger.io/dagger"
	"universe.dagger.io/bash"
	"github.com/h8r-dev/gin-vue/plans/cuelib/helm"
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
			APP_NAME:     string
			GITHUB_TOKEN: dagger.#Secret
		}
		filesystem: {
			"code/": read: contents:          dagger.#FS
			ingress_version: write: contents: actions.getIngressVersion.export.files["/result"]
		}
	}

	actions: {
		kubectl: #Kubectl

		// Get ingress version, i.e. v1 or v1beta1
		getIngressVersion: bash.#Run & {
			input:   kubectl.image.output
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
			export: files: "/result": _
		}

		// Should be the chat you want to install
		installNocalhost: #InstallChart & {
			releasename: "nocalhost"
			repository:  "https://nocalhost-helm.pkg.coding.net/nocalhost/nocalhost"
			chartname:   "nocalhost"
			kubeconfig:  client.env.KUBECONFIG_DATA
		}

		testCreateH8rIngress: #CreateH8rIngress & {
			name:   "just-a-test"
			host:   "1.1.1.1"
			domain: "foo.bar"
			port:   "80"
		}

		installIngress: helm.#Chart & {
			name:       "ingress-nginx"
			repository: "https://h8r-helm.pkg.coding.net/release/helm"
			chart:      "ingress-nginx"
			namespace:  "ingress-nginx"
			action:     "installOrUpgrade"
			kubeconfig: client.commands.kubeconfig.stdout
			values:     #ingressNginxSetting
			wait:       true
		}

		createRepos: #CreateRepos & {
			appname:     client.env.APP_NAME
			sourcecode:  client.filesystem."code".read.contents
			githubtoken: client.env.GITHUB_TOKEN
		}
		deleteRepos: #DeleteRepos & {
			appname:     client.env.APP_NAME
			githubtoken: client.env.GITHUB_TOKEN
		}
	}
}
