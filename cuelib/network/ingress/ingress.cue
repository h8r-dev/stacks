package ingress

import (
	"encoding/yaml"
	"strings"
	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"universe.dagger.io/bash"
	"universe.dagger.io/docker"
	"github.com/h8r-dev/cuelib/utils/base"
)

#Ingress: {
	// and generate selectors.
	name: string

	// Namespace to deploy
	namespace: string | *"default"

	// Class name.
	className: string

	// Host name
	hostName: string

	// Path
	path: string

	// Service name
	backendServiceName: string

	// 80 is the default port.
	backendServicePort: int | *80

	// cluster version, such v1, v1beta1
	ingressVersion: string

	// Ingress manifest
	// generate the resource manifest.

	manifest: {
		if strings.TrimSpace(ingressVersion) == "v1" {
			apiVersion: "networking.k8s.io/v1"
			kind:       "Ingress"
			metadata: {
				"name":      name
				"namespace": namespace
				annotations: {
					h8r:  "true"
					host: hostName
				}
			}
			spec: {
				ingressClassName: "nginx"
				rules: [{
					host: hostName
					http: paths: [{
						"path":   path
						pathType: "Prefix"
						backend: service: {
							name: backendServiceName
							port: number: backendServicePort
						}
					}]
				}]
			}
		}
		if strings.TrimSpace(ingressVersion) == "v1beta1" {
			apiVersion: "networking.k8s.io/v1beta1"
			kind:       "Ingress"
			metadata: {
				"name":      name
				"namespace": namespace
				annotations: {
					h8r:                           "true"
					host:                          hostName
					"kubernetes.io/ingress.class": "nginx"
				}
			}
			spec: rules: [{
				host: hostName
				http: paths: [{
					"path":   path
					pathType: "Prefix"
					backend: {
						serviceName: backendServiceName
						servicePort: backendServicePort
					}
				}]
			}]
		}
	}

	manifestStream: yaml.Marshal(manifest)
}

#GetIngressEndpoint: {
	// Kube config file
	kubeconfig: string | dagger.#Secret

	// namespace
	namespace: string | *"ingress-nginx"

	#code: #"""
		while ! kubectl get ns $KUBE_NAMESPACE; do sleep 1; done
		while ! kubectl get svc/ingress-nginx-controller -n $KUBE_NAMESPACE; do sleep 1; done
		external_ip=""; while [ -z $external_ip ]; do echo "Waiting for end point..."; external_ip=$(kubectl get svc ingress-nginx-controller --namespace $KUBE_NAMESPACE --template="{{range .status.loadBalancer.ingress}}{{.ip}}{{end}}"); [ -z "$external_ip" ] && sleep 1; done; echo "End point ready-" && echo $external_ip; export endpoint=$external_ip
		#kubectl get services --namespace $KUBE_NAMESPACE ingress-nginx-controller --output jsonpath='{.status.loadBalancer.ingress[0].ip}' > /endpoint
		printf $endpoint | awk '$1=$1' > /endpoint
		"""#

	_kubectl: base.#Kubectl

	get: bash.#Run & {
		input:  _kubectl.output
		always: true
		env: {
			KUBECONFIG:     "/kubeconfig"
			KUBE_NAMESPACE: namespace
		}
		script: contents: #code
		mounts: "kubeconfig": {
			dest:     "/kubeconfig"
			contents: kubeconfig
		}
		//export: files: "/endpoint": string
	}

	contentFile: core.#ReadFile & {
		input: get.output.rootfs
		path:  "/endpoint"
	}

	content: strings.Replace(contentFile.contents, "\n", "", -1)

	//content: get.export.files."/endpoint".content
}

// Get ingress version, i.e. v1 or v1beta1
#GetIngressVersion: {
	kubeconfig: string | dagger.#Secret

	image: docker.#Image | *base.#Kubectl

	get: bash.#Run & {
		input:   image
		workdir: "/src"
		mounts: "KubeConfig Data": {
			dest:     "/kubeconfig"
			contents: kubeconfig
		}
		script: contents: #"""
			set +e
			ingress_result=$(kubectl --kubeconfig /kubeconfig api-resources --api-group=networking.k8s.io)
			set -e
			if [[ $ingress_result =~ "networking.k8s.io/v1beta1" ]]; then
				echo "the ingress version is v1beta1"
				printf 'v1beta1' > /result
			elif [[ $ingress_result =~ "networking.k8s.io/v1" ]]; then
				echo "the ingress version is v1"
				printf 'v1' > /result
			else
				echo "error: could not find ingress version"
				exit 1
			fi
			"""#
		//export: files: "/result": string
		always: true
	}

	contentFile: core.#ReadFile & {
		input: get.output.rootfs
		path:  "/result"
	}

	content: strings.TrimSpace(contentFile.contents)
	//content: strings.TrimSpace(get.export.files."/result".content)
}
