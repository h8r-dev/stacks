package status

import (
	"dagger.io/dagger"
	"strconv"
	"universe.dagger.io/bash"
	"universe.dagger.io/docker"
)

// Set or get status, storage with secret name `heighliner-status` in heighliner-system namespace
#Status: {
	// Secret key
	keyName: string

	// Secret value
	keyValue: string

	// Kubeconfig file
	kubeconfig: string | dagger.#Secret

	// Action TODO get and set
	action: "get" | "set" | *"setget"

	// Namespace
	namespace: string | *"heighliner-system"

	_kubectlImage: docker.#Pull & {
		source: "index.docker.io/alpine/k8s:1.22.6"
	}

	waitFor: bool | *true

	run: bash.#Run & {
		input: _kubectlImage.output
		script: contents: #"""
			kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
			
			# get secret
			secret=$(kubectl get secrets/heighliner-status --template={{.data.$KEY_NAME}} --ignore-not-found -n $NAMESPACE | base64 -d)
			if [ -z "$secret" ]; then
				kubectl create secret generic heighliner-status --from-literal=$KEY_NAME=$KEY_VALUE --dry-run=client -o yaml -n $NAMESPACE | kubectl apply -f -
				echo 'secret value: '$KEY_VALUE
				printf "$KEY_VALUE" > /result
				exit 0
			else
				echo 'secret value: '$secret
			fi
			printf $secret > /result
			"""#
		mounts: "kubeconfig": {
			dest:     "/etc/kubernetes/config"
			contents: kubeconfig
		}
		env: {
			WAIT_FOR:   strconv.FormatBool(waitFor)
			KUBECONFIG: "/etc/kubernetes/config"
			NAMESPACE:  namespace
			KEY_NAME:   keyName
			KEY_VALUE:  keyValue
		}
		always: true
		export: files: "/result": string
	}

	content: run.export.files."/result"
	output:  run.output
	success: run.success
}
