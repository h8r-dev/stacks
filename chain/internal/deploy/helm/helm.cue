package helm

import (
	"strconv"
	"universe.dagger.io/docker"
	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"github.com/h8r-dev/stacks/chain/internal/utils/base"
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

	set: string | *"heighlinerDomain=heighliner.dev"

	// Kube config file
	kubeconfig: string | dagger.#Secret

	// Helm version
	version: *"3.5.2" | string

	chartVersion: string

	// Kubectl version
	kubectlVersion: *"v1.23.5" | string

	// Wait for all pods to be ready before marking the release as successful
	waitFor: bool | *true

	_baseImage: base.#Image

	_writeYaml: output: core.#FS

	if values != null {
		_writeYaml: core.#WriteFile & {
			input:    dagger.#Scratch
			path:     "/values.yaml"
			contents: values
		}
	}

	_writeYamlOutput: _writeYaml.output

	run: docker.#Run & {
		input:  _baseImage.output
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
			HELM_SET:     set
			if repository != null {
				HELM_CHART_VERSION: chartVersion
			}
		}
		mounts: {
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
	}

	output: run.output

	success: run.success
}
