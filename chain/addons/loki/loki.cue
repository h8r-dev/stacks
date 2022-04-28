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
				mkdir -p /scaffold/$OUTPUT_PATH/infra/loki
				tar -zxvf ./loki-stack-$VERSION.tgz -C /scaffold/$OUTPUT_PATH/infra/loki
				mv /scaffold/$OUTPUT_PATH/infra/loki/loki-stack /scaffold/$OUTPUT_PATH/infra/loki/app
				echo "loki..."
				cat <<EOF >/scaffold/$OUTPUT_PATH/infra/loki/output-hook.sh
				echo '{"username": "admin", "password": "123456","test":"loki"}'
				EOF
				chmod +x /scaffold/$OUTPUT_PATH/infra/loki/output-hook.sh
			"""#
	}
	output: #Output & {
		image:   do.output
		success: do.success
	}
}
