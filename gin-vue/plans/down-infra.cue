package main

import (
	"dagger.io/dagger"
	"universe.dagger.io/bash"
	"universe.dagger.io/docker"
)

dagger.#Plan & {
	client: env: KUBECONFIG_DATA: dagger.#Secret

	actions: {
		deleteNocalhost: #DeleteChart & {
			releasename: "nocalhost"
			kubeconfig:  client.env.KUBECONFIG_DATA
		}
	}
}

#Helm: {
	helmversion:    string | *"3.8.1"
	kubectlversion: string | *"1.23.5"
	packages: [pkgName=string]: version: string | *""
	packages: {
		bash: {}
		curl: {}
	}
	image: docker.#Build & {
		steps: [
			docker.#Pull & {
				source: "index.docker.io/alpine/helm:\(helmversion)"
			},
			for pkgName, pkg in packages {
				docker.#Run & {
					command: {
						name: "apk"
						args: ["add", "\(pkgName)\(pkg.version)"]
						flags: {
							"-U":         true
							"--no-cache": true
						}
					}
				}
			},
			bash.#Run & {
				script: contents: #"""
					curl -LO https://dl.k8s.io/release/\#(kubectlversion)/bin/linux/amd64/kubectl
					chmod +x kubectl
					mv kubectl /usr/local/bin/
					"""#
			},
		]
	}
	output: image.output
}

#DeleteChart: {
	// input values
	releasename: string
	kubeconfig:  dagger.#Secret

	// dependencies
	deps: #Helm

	run: bash.#Run & {
		input: deps.output
		mounts: {
			"/etc/kubernetes/config": dagger.#Mount & {
				dest:     "/etc/kubernetes/config"
				type:     "secret"
				contents: kubeconfig
			}
		}
		env: {
			KUBECONFIG:   "/etc/kubernetes/config"
			RELEASE_NAME: releasename
		}
		script: contents: #"""
			helm delete $RELEASE_NAME
			"""#
	}
}
