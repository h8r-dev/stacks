package check

import (
	"alpha.dagger.io/dagger"
	"alpha.dagger.io/dagger/op"
	"alpha.dagger.io/kubernetes"
)

#TestOutput: {
	// TODO default repoDir path, now you can set "." with dagger dir type
	testString: string

	#up: [
		op.#FetchContainer & {
			ref: "ubuntu:latest"
		},

		op.#Exec & {
			env: TEST: testString
			args: [
				"/bin/bash",
				"--noprofile",
				"--norc",
				"-eo",
				"pipefail",
				"-c",
				#"""
					echo "s"$TEST"sss"
					"""#,
			]
			always: true
		},
	]
}

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

#GetIngressVersion: {
	// Kube config file
	kubeconfig: dagger.#Input & {string | dagger.#Secret}

	// Get ingress version, such v1, v1beta1
	get: {
		string

		#up: [
			op.#Load & {
				from: kubernetes.#Kubectl & {
					version: "v1.22.5"
				}
			},

			op.#Exec & {
				always: true
				args: [
					"/bin/bash",
					"--noprofile",
					"--norc",
					"-eo",
					"pipefail",
					"-c",
					#"""
							ingress_result=$(kubectl api-resources --api-group=networking.k8s.io)
							if [[ $ingress_result =~ "v1beta1" ]]; then
								echo 'v1beta1' > /result
							else
								echo 'v1' > /result
							fi
						"""#,
				]
				env: KUBECONFIG: "/kubeconfig"
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
