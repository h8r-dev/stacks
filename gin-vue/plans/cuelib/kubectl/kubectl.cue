package kubectl

import(
    "universe.dagger.io/alpine"
	"universe.dagger.io/docker"
)

#Kubectl: {
	version: string | *"v1.23.5"
	docker.#Build & {
		steps: [
			alpine.#Build & {
				packages: {
					bash: {}
					curl: {}
				}
			},

			docker.#Run & {
				command: {
					name: "sh"
					flags: "-c": #"""
						curl -LO https://dl.k8s.io/release/\#(version)/bin/linux/amd64/kubectl
						chmod +x kubectl
						mv kubectl /usr/local/bin/
					"""#
				}
			},
		]
	}
}