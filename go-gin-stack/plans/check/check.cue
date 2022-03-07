package check

import (
	"alpha.dagger.io/dagger"
	"alpha.dagger.io/dagger/op"
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