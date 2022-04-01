package helm

import (
	"strconv"
	"universe.dagger.io/docker"
	"dagger.io/dagger"
	"github.com/h8r-dev/gin-vue/plans/cuelib/base"
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
	waitFor: bool | *true

	_kubectl: base.#Kubectl

	// build: docker.#Build & {
	//  steps: [
	//   alpine.#Build & {
	//    packages: {
	//     jq: {}
	//     curl: {}
	//    }
	//   },
	//   docker.#Run & {
	//    workdir: "/src"
	//    command: {
	//     name: "sh"
	//     flags: "-c": #"""
	//      curl -LO https://dl.k8s.io/release/\#(kubectlVersion)/bin/linux/amd64/kubectl
	//      chmod +x kubectl
	//      mv kubectl /usr/local/bin/
	//      mkdir /helm
	//      """#
	//    }
	//   },
	//   docker.#Run & {
	//    env: HELM_VERSION: version
	//    command: {
	//     name: "sh"
	//     flags: "-c": #"""
	//      curl -sfL -S https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz | \
	//      tar -zx -C /tmp && \
	//      mv /tmp/linux-amd64/helm /usr/local/bin && \
	//      chmod +x /usr/local/bin/helm
	//      """#
	//    }
	//   },
	//   // if (kubeconfig & string) != _|_ {
	//   //  #WriteFile & {
	//   //   contents: kubeconfig
	//   //   path: "/kubeconfig"
	//   //  }
	//   // },

	//  ]
	// }
	_writeYaml: output: dagger.#FS

	if values != null {
		_writeYaml: dagger.#WriteFile & {
			input:    dagger.#Scratch
			path:     "/values.yaml"
			contents: values
		}
	}

	_writeYamlOutput: _writeYaml.output

	// if values != null {
	//  writeYaml: dagger.#WriteFile & {
	//   input:    dagger.#Scratch
	//   path:     "/values.yaml"
	//   contents: values
	//  }
	// }

	// writeChart: dagger.#WriteFile & {
	//  input:    dagger.#Scratch
	//  path:     "/chart.yaml"
	//  contents: chart
	// }

	// build: docker.#Run & {
	//  input: _kubectl.output
	//  mounts: {
	//   "helm": {
	//    contents: writeYaml.output
	//    dest:     "/helm"
	//   }
	//  }
	// }

	run: docker.#Run & {
		input:  _kubectl.output
		always: true
		command: {
			name: "sh"
			flags: "-c": #code
		}
		env: {
			"waitFor":      strconv.FormatBool(waitFor)
			KUBECONFIG:     "/kubeconfig"
			KUBE_NAMESPACE: namespace

			if repository != null {
				HELM_REPO: repository
			}
			HELM_NAME:    name
			CHART_NAME:   chart
			HELM_ACTION:  action
			HELM_TIMEOUT: timeout
			HELM_WAIT:    strconv.FormatBool(wait)
			HELM_ATOMIC:  strconv.FormatBool(atomic)
		}
		mounts: {
			// if chartSource != null && chart == null {
			//  "/helm/chart": from: chartSource
			// }

			"kubeconfig": {
				dest:     "/kubeconfig"
				contents: kubeconfig
			}

			if values != null {
				helm: {
					contents: _writeYamlOutput
					dest:     "/helm"
				}
			}
		}
		// export: directories: "/output": _
	}

	output: run.output

	success: run.success
}
