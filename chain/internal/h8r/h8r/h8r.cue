package h8r

import (
	"strconv"
	"universe.dagger.io/alpine"
	"universe.dagger.io/bash"
)

// craete ingress by h8s server
#CreateH8rIngress: {
	// Ingress name
	name:             string
	host:             string
	domain:           string
	port:             string | *"80"
	h8rServerAddress: string | *"api.stack.h8r.io/api/v1/cluster/ingress"
	always:           bool | *true

	baseImage: alpine.#Build & {
		packages: {
			bash: {}
			curl: {}
		}
	}

	create: bash.#Run & {
		input:    baseImage.output
		"always": always
		env: HOST:        host
		script: contents: #"""
			sh_c='sh -c'
			echo $HOST'-'\#(name)'-'\#(domain)'-'\#(port)
			data_raw='{"name":"\#(name)","host":"\#(host)","domain":"\#(domain)","port":"\#(port)"}'
			do_create="curl -sw '\n%{http_code}' --retry 3 --retry-delay 2 --insecure -X POST --header 'Content-Type: application/json' --data-raw '$data_raw' \#(h8rServerAddress)"
			messages="$($sh_c "$do_create")"
			http_code=$(echo "$messages" |  tail -1)
			if [ "$http_code" -ne "200" ]; then
				#// echo error messages
				echo "$messages"
				exit 1
			fi
			"""#
	}

	output: create.output

	success: create.success
}

// delet ingress by h8s server
#DeleteH8rIngress: {
	// Ingress name
	name:             string
	h8rServerAddress: string | *"api.stack.h8r.io/api/v1/cluster/ingress"
	waitFor:          bool | *false

	baseImage: alpine.#Build & {
		packages: {
			bash: {}
			curl: {}
		}
	}

	create: bash.#Run & {
		input: baseImage.output
		env: {
			NAME:     name
			WAIT_FOR: strconv.FormatBool(waitFor)
		}
		script: contents: #"""
			sh_c='sh -c'
			data_raw='{"name":"$NAME"}'
			do_create="curl -sw '\n%{http_code}' --retry 3 --retry-delay 2 --insecure -X DELETE --header 'Content-Type: application/json' --data-raw '$data_raw' \#(h8rServerAddress)"
			messages="$($sh_c "$do_create")"
			http_code=$(echo "$messages" |  tail -1)
			if [ "$http_code" -ne "200" ]; then
				#// echo error messages
				echo "$messages"
				exit 1
			fi
			"""#
	}

	output: create.output

	success: create.success
}
