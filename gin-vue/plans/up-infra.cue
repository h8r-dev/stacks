package main

import (
	"dagger.io/dagger"
	"universe.dagger.io/alpine"
	"universe.dagger.io/bash"
	"universe.dagger.io/docker"
)

// Automatically setup infra resources:
//   Nocalhost, Loki, Granfana, Prometheus, ArgoCD

#Kubectl: {
	version: string | *"v1.23.5"
	image:   docker.#Build & {
		steps: [
			alpine.#Build & {
				packages: {
					bash: {}
					curl: {}
				}
			},
			bash.#Run & {
				workdir: "/src"
				script: contents: #"""
					curl -LO https://dl.k8s.io/release/\#(version)/bin/linux/amd64/kubectl
					chmod +x kubectl
					mv kubectl /usr/local/bin/
					"""#
			},
		]
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

#InstallChart: {
	// input values
	releasename: string
	repository:  string
	chartname:   string
	namespace:   string | *""
	kubeconfig:  dagger.#Secret

	// dependencies
	deps: #Helm

	run: bash.#Run & {
		input: deps.output
		mounts: "/etc/kubernetes/config": dagger.#Mount & {
			dest:     "/etc/kubernetes/config"
			type:     "secret"
			contents: kubeconfig
		}
		env: {
			KUBECONFIG:     "/etc/kubernetes/config"
			HELM_NAMESPACE: namespace
			TMP_REPO:       repository
			RELEASE_NAME:   releasename
			CHART_NAME:     chartname
		}
		script: contents: #"""
			helm repo add tmp-repo $TMP_REPO
			helm install $RELEASE_NAME tmp-repo/$CHART_NAME
			"""#
	}
}

// craete ingress by h8s server
#CreateH8rIngress: {
	// Ingress name
	name: string
	// Host IP
	host: string
	// Domain
	domain: string
	// Port
	port: string | *"80"

	image: alpine.#Build & {
		packages: {
			bash: {}
			jq: {}
			curl: {}
			sed: {}
		}
	}

	create: bash.#Run & {
		input: image.output
		env: {
			NAME:   name
			HOST:   host
            DOMAIN: domain
            PORT:   port
		}
		script: contents: #"""
			export HOST=$(echo $HOST | awk '$1=$1')
			echo '{"name":"'$NAME'","host":"'$HOST'","domain":"'$DOMAIN'","port":"'$PORT'"}'
			check=$(curl --retry 50 --retry-delay 2 --insecure -X POST --header 'Content-Type: application/json' --data-raw '{"name":"'$NAME'","host":"'$HOST'","domain":"'$DOMAIN'","port":"'$PORT'"}' api.stack.h8r.io/api/v1/cluster/ingress | jq .message | sed 's/\"//g')
			echo $check
			if [ "$check" == "ok" ]; then
				echo "Create h8r ingress success"
			else
				echo "Create h8r ingress fail"
				exit 1
			fi
			"""#
	}
}


dagger.#Plan & {
	client: env: KUBECONFIG_DATA: dagger.#Secret
	client: filesystem: ingress_version: write: contents: actions.getIngressVersion.export.files["/result"]

	actions: {
		kubectl: #Kubectl & {version: "v1.23.5"}

		// Get ingress version, i.e. v1 or v1beta1
		getIngressVersion: bash.#Run & {
			input:   kubectl.image.output
			workdir: "/src"
			mounts: "KubeConfig Data": {
				dest:     "/kubeconfig"
				contents: client.env.KUBECONFIG_DATA
			}
			script: contents: #"""
				ingress_result=$(kubectl --kubeconfig /kubeconfig api-resources --api-group=networking.k8s.io)
				if [[ $ingress_result =~ "v1beta1" ]]; then
				 echo 'v1beta1' > /result
				else
				 echo 'v1' > /result
				fi
				"""#
			export: files: "/result": _
		}

		// Should be the chat you want to install
		installNocalhost: #InstallChart & {
			releasename: "nocalhost"
			repository:  "https://nocalhost-helm.pkg.coding.net/nocalhost/nocalhost"
			chartname:   "nocalhost"
			kubeconfig:  client.env.KUBECONFIG_DATA
		}

		testCreateH8rIngress: #CreateH8rIngress & {
			name: "just-a-test"
			host: "1.1.1.1"
			domain: "foo.bar"
			port: "80"
		}
	}
}
