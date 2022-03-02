package check

import (
	"alpha.dagger.io/dagger"
	"alpha.dagger.io/dagger/op"
	"encoding/yaml"
	"alpha.dagger.io/alpine"
	"alpha.dagger.io/kubernetes"
)

#CheckInfra: {
    // TODO default repoDir path, now you can set "." with dagger dir type
    sourceCodeDir: dagger.#Artifact @dagger(input)
    
    // Check infra precondition
    check: {
        string

        #up: [
            op.#FetchContainer & {
				ref: "ubuntu:latest"
			},

            op.#Exec & {
				mount: "/root": from: sourceCodeDir
                args: [
					"/bin/bash",
					"--noprofile",
					"--norc",
					"-eo",
					"pipefail",
					"-c",
                    #"""
						FILE=/root/infra/kubeconfig/config.yaml
						if [ ! -f "$FILE" ] || [ ! -s "$FILE" ]; then
							echo "Please add your kubeconfig to infra/kubeconfig/config.yaml file"
							exit 1
						fi
						echo "OK!" >  /success
						"""#,
				]
				always: true
            },

            op.#Export & {
				source: "/success"
				format: "string"
			},
        ]
    } @dagger(output)
}

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

	// Ingress manifest
	// generate the resource manifest.
	manifest: {
		apiVersion: "networking.k8s.io/v1beta1"
		kind:       "Ingress"
		metadata: {
			"name": name
			"namespace": namespace
			annotations: {
				"h8r": "true"
				"host": hostName
				"kubernetes.io/ingress.class": "nginx"
			}
		}
		spec: {
			rules: [{
				host:  hostName
				http: paths: [{
					"path": path
					pathType: "Prefix"
					backend: {
						serviceName: backendServiceName
						servicePort: backendServicePort
						// service: {
						// 	"name": backendServiceName
						// 	port: {
						// 		"number": backendServicePort
						// 	}
						// }
					}
				}]
			}]
		}
	}
	
	// MarshalStream
	manifestStream: yaml.MarshalStream([manifest])
}

// Create H8r Ingress, Service, Endpionts
#CreateH8rIngress: {
	// Ingress name
	name: dagger.#Input & {string}
	
	// Host IP
	host: dagger.#Input & {string}

	// Domain
	domain: dagger.#Input & {string}

	// Port
	port: dagger.#Input & {string | *"80"}

	create: {
		#up: [
			op.#Load & {
				from: alpine.#Image & {
					package: bash:         true
					package: curl:         true
					package: jq: true
					package: sed: true
				}
			},

			op.#Exec & {
				dir: "/root"
				env: {
					NAME:    name
					HOST: host
                    DOMAIN: domain
                    PORT: port
				}
				args: [
                    "/bin/bash",
                    "--noprofile",
                    "--norc",
                    "-eo",
                    "pipefail",
                    "-c",
                    #"""
					export HOST=$(echo $HOST | awk '$1=$1')
					echo '{"name":"'$NAME'","host":"'$HOST'","domain":"'$DOMAIN'","port":"'$PORT'"}'
					check=$(curl --insecure -X POST --header 'Content-Type: application/json' --data-raw '{"name":"'$NAME'","host":"'$HOST'","domain":"'$DOMAIN'","port":"'$PORT'"}' api.stack.h8r.io/api/v1/cluster/ingress | jq .message | sed 's/\"//g')
					if [ "$check" == "ok" ]; then
						echo "Create h8r ingress success"
					else
						echo "Create h8r ingress fail"
						exit 1
					fi
					"""#,
				]
				always: true
			},
		]
	}
}

#GetIngressEndpoint: {
	// Kube config file
	kubeconfig: dagger.#Input & {dagger.#Secret}

	// namespace
	namespace: dagger.#Input & {string | *"ingress-nginx"}

	#code: #"""
		while ! kubectl get ns $KUBE_NAMESPACE; do sleep 1; done
		while ! kubectl get svc/ingress-nginx-controller -n $KUBE_NAMESPACE; do sleep 1; done
		external_ip=""; while [ -z $external_ip ]; do echo "Waiting for end point..."; external_ip=$(kubectl get svc ingress-nginx-controller --namespace $KUBE_NAMESPACE --template="{{range .status.loadBalancer.ingress}}{{.ip}}{{end}}"); [ -z "$external_ip" ] && sleep 1; done; echo "End point ready-" && echo $external_ip; export endpoint=$external_ip
		#kubectl get services --namespace $KUBE_NAMESPACE ingress-nginx-controller --output jsonpath='{.status.loadBalancer.ingress[0].ip}' > /endpoint
		echo $endpoint | awk '$1=$1' > /endpoint
		"""#

	// Ingress nginx endpoint
	get: {
		string

		#up: [
			op.#Load & {
				from: kubernetes.#Kubectl
			},

			op.#WriteFile & {
				dest:    "/entrypoint.sh"
				content: #code
			},

			op.#Exec & {
				always: true
				args: [
					"/bin/bash",
					"--noprofile",
					"--norc",
					"-eo",
					"pipefail",
					"/entrypoint.sh",
				]
				env: {
					KUBECONFIG:     "/kubeconfig"
					KUBE_NAMESPACE: namespace
				}
				if (kubeconfig & dagger.#Secret) != _|_ {
					mount: "/kubeconfig": secret: kubeconfig
				}
			},

			op.#Export & {
				source: "/endpoint"
				format: "string"
			},
		]
	} @dagger(output)
}

#GetKubectlOutput: {
	// Kube config file
	kubeconfig: dagger.#Input & {dagger.#Secret}

	// Code
	runCode: string
	
	get: {
		string

		#up: [
			op.#Load & {
				from: kubernetes.#Kubectl
			},

			op.#WriteFile & {
				dest:    "/entrypoint.sh"
				content: runCode
			},

			op.#Exec & {
				always: true
				args: [
					"/bin/bash",
					"--noprofile",
					"--norc",
					"-eo",
					"pipefail",
					"cat /entrypoint.sh",
				]
				env: {
					KUBECONFIG:     "/kubeconfig"
				}
				if (kubeconfig & dagger.#Secret) != _|_ {
					mount: "/kubeconfig": secret: kubeconfig
				}
			},

			op.#Export & {
				source: "/result"
				format: "string"
			},
		]
		
	} @dagger(output)
}

#GetLokiSecret: {
	// Kube config file
	kubeconfig: dagger.#Input & {dagger.#Secret}

	// namespace
	namespace: dagger.#Input & {string | *"loki"}

	#code: #"""
	while ! kubectl get secret/loki-grafana -n $KUBE_NAMESPACE; do sleep 1; done
	secret=$(kubectl get secret --namespace $KUBE_NAMESPACE loki-grafana -o jsonpath='{.data.admin-password}' | base64 -d ; echo)
	echo $secret > /result
	"""#

	// Grafana secret, password of admin user
	get: {
		string

		#up: [
			op.#Load & {
				from: kubernetes.#Kubectl
			},

			op.#WriteFile & {
				dest:    "/entrypoint.sh"
				content: #code
			},

			op.#Exec & {
				always: true
				args: [
					"/bin/bash",
					"--noprofile",
					"--norc",
					"-eo",
					"pipefail",
					"/entrypoint.sh",
				]
				env: {
					KUBECONFIG:     "/kubeconfig"
					KUBE_NAMESPACE: namespace
				}
				if (kubeconfig & dagger.#Secret) != _|_ {
					mount: "/kubeconfig": secret: kubeconfig
				}
			},

			op.#Export & {
				source: "/result"
				format: "string"
			},
		]
	} @dagger(output)
}