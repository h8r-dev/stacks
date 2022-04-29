package loki

import (
	"universe.dagger.io/bash"
)

#Instance: {
	input: #Input
	do:    bash.#Run & {
		"input": input.image
		env: {
			VERSION:     input.version
			OUTPUT_PATH: input.helmName
		}
		workdir: "/tmp"
		script: contents: #"""
				helm pull loki-stack --repo https://grafana.github.io/helm-charts --version $VERSION
				mkdir -p /scaffold/$OUTPUT_PATH/infra
				tar -zxvf ./loki-stack-$VERSION.tgz -C /scaffold/$OUTPUT_PATH/infra
				mv /scaffold/$OUTPUT_PATH/infra/loki-stack /scaffold/$OUTPUT_PATH/infra/loki
				#touch /scaffold/$OUTPUT_PATH/infra/loki-cd-output-hook.sh
				#chmod +x /scaffold/$OUTPUT_PATH/infra/loki-cd-output-hook.sh
				#cat <<EOF >> /scaffold/$OUTPUT_PATH/infra/loki-cd-output-hook.sh
			#echo '{"username":"admin","password":"123456"}' > /scaffold/$OUTPUT_PATH/infra/loki-cd-output-hook.txt
			"""#
	}
	output: #Output & {
		image:   do.output
		success: do.success
	}
}
