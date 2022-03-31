package helm

import (
	"strconv"
	"universe.dagger.io/docker"
	"dagger.io/dagger"
	"github.com/h8r-dev/gin-vue/plans/cuelib/fs"
)

// Install a Helm chart
#Chart: {

	// Helm deployment name
	name: string

	// Helm chart to install from source
	chartSource: *null | dagger.#FS

	// Helm chart to install from repository
	chart: *null | string

	// Helm chart repository
	repository: *null | string

	// Helm values (either a YAML string or a Cue structure)
	values: *null | string

	// Kubernetes Namespace to deploy to
	namespace: string

	// Helm action to apply
	action: *"installOrUpgrade" | "install" | "upgrade"

	// time to wait for any individual Kubernetes operation (like Jobs for hooks)
	timeout: string | *"10m"

	// if set, will wait until all Pods, PVCs, Services, and minimum number of
	// Pods of a Deployment, StatefulSet, or ReplicaSet are in a ready state
	// before marking the release as successful.
	// It will wait for as long as timeout
	wait: *true | bool

	// if set, installation process purges chart on fail.
	// The wait option will be set automatically if atomic is used
	atomic: *true | bool

	// Kube config file
	kubeconfig: string | dagger.#Secret

	// Helm version
	version: *"3.5.2" | string

	// Kubectl version
	kubectlVersion: *"v1.23.5" | string

	// Wait for
	// waitFor: [string]: from: dagger.#FS

	_imageVersion: string | *"3.15.0@sha256:21a3deaa0d32a8057914f36584b5288d2e5ecc984380bc0118285c70fa8c9300"
	_packages: [pkgName=string]: version: string | *""
	_packages: {
		jq: {}
		curl: {}
	}

	build: docker.#Build & {
		steps: [
			docker.#Pull & {
				source: "index.docker.io/alpine:\(_imageVersion)"
			},
			for pkgName, pkg in _packages {
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
			//   alpine.#Build & {
			//    packages: {
			//     jq: {}
			//     curl: {}
			//    }
			//   },
			docker.#Run & {
				workdir: "/src"
				command: {
					name: "sh"
					flags: "-c": #"""
						curl -LO https://dl.k8s.io/release/\#(kubectlVersion)/bin/linux/amd64/kubectl
						chmod +x kubectl
						mv kubectl /usr/local/bin/
						mkdir /helm
						"""#
				}
			},
			docker.#Run & {
				env: HELM_VERSION: version
				command: {
					name: "sh"
					flags: "-c": #"""
						curl -sfL -S https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz | \
						tar -zx -C /tmp && \
						mv /tmp/linux-amd64/helm /usr/local/bin && \
						chmod +x /usr/local/bin/helm
						"""#
				}
			},
			// if (kubeconfig & string) != _|_ {
			//  #WriteFile & {
			//   contents: kubeconfig
			//   path: "/kubeconfig"
			//  }
			// },
			if chart != null {
				fs.#WriteFile & {
					contents: chart
					path:     "/helm/chart"
				}
			},
			if values != null {
				fs.#WriteFile & {
					contents: values
					path:     "/helm/values.yaml"
				}
			},
			docker.#Run & {
				always: true
				command: {
					name: "sh"
					flags: "-c": #code
				}
				env: {
					KUBECONFIG:     "/kubeconfig"
					KUBE_NAMESPACE: namespace

					if repository != null {
						HELM_REPO: repository
					}
					HELM_NAME:    name
					HELM_ACTION:  action
					HELM_TIMEOUT: timeout
					HELM_WAIT:    strconv.FormatBool(wait)
					HELM_ATOMIC:  strconv.FormatBool(atomic)
				}
				mounts: {
					if chartSource != null && chart == null {
						"/helm/chart": from: chartSource
					}

					"kubeconfig": {
						dest:     "/kubeconfig"
						contents: kubeconfig
					}
					// if (kubeconfig & dagger.#Secret) != _|_ {
					//  "/kubeconfig": secret: kubeconfig
					// }
					// if waitFor != null {
					//  for dest, o in waitFor {
					//   "\(dest)": o
					//  }
					// }
				}
				// export: directories: "/output": _
			},
		]
	}

	done: docker.#Run & {
		always: true
		input:  build.output
		command: {
			name: "sh"
			flags: "-c": "echo helm-install-done"
		}
	}

	success: done.success
}
