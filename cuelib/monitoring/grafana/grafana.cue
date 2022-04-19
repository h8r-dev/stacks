package grafana

import (
	"dagger.io/dagger"
	"universe.dagger.io/bash"
	"github.com/h8r-dev/stacks/cuelib/utils/base"
	"strconv"
)

#GetGrafanaSecret: {
	// Kube config file
	kubeconfig: string | dagger.#Secret

	// Namespace
	namespace: string | *"monitoring"

	// Secret Name
	secretName: string

	waitFor: bool

	#code: #"""
		while ! kubectl get secret/$SECRET_NAME -n $KUBE_NAMESPACE;
		do
			sleep 5
			echo 'wait for secret/'$SECRET_NAME
		done
		secret=$(kubectl get secret --namespace $KUBE_NAMESPACE $SECRET_NAME -o jsonpath='{.data.admin-password}' | base64 -d ; echo)
		echo $secret
		printf $secret > /result
		"""#

	_kubectl: base.#Kubectl

	// Grafana secret, password of admin user
	get: bash.#Run & {
		input:  _kubectl.output
		always: true
		env: {
			KUBECONFIG:     "/kubeconfig"
			KUBE_NAMESPACE: namespace
			SECRET_NAME:    secretName
			WAIT_FOR:       strconv.FormatBool(waitFor)
		}
		script: contents: #code
		mounts: "kubeconfig": {
			dest:     "/kubeconfig"
			contents: kubeconfig
		}
		export: files: "/result": _
	}

	secret: get.export.files."/result"
}
