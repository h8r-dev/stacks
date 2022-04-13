package base

import (
	"universe.dagger.io/alpine"
	"universe.dagger.io/docker"
)

#Kubectl: {
	version:     string | *"v1.23.5"
	helmVersion: *"v3.5.2" | string

	dep: alpine.#Build & {
		packages: {
			bash: {}
			curl: {}
			jq: {}
		}
	}

	run: docker.#Run & {
		input: dep.output
		command: {
			name: "sh"
			flags: "-c": #"""
				# install kubectl
				curl -LO https://dl.k8s.io/release/\#(version)/bin/linux/amd64/kubectl
				chmod +x kubectl
				mv kubectl /usr/local/bin/

				# install helm
				curl -sfL -S https://get.helm.sh/helm-\#(helmVersion)-linux-amd64.tar.gz | \
				tar -zx -C /tmp && \
				mv /tmp/linux-amd64/helm /usr/local/bin && \
				chmod +x /usr/local/bin/helm
			"""#
		}
	}

	output: run.output
}
