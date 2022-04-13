package grafana

import (
	"universe.dagger.io/bash"
	"github.com/h8r-dev/cuelib/utils/base"
	"strconv"
)

#CreateLokiDataSource: {
	// Grafana Url
	url: string

	// Grafana username
	username: string

	// Grafana password
	password: string

	waitFor: bool | *true

	code: #"""
		PASSWORD=$(echo $PASSWORD | xargs)
		url=$NAME:$PASSWORD@$URL
		# check datasource
		source=( $(curl $url/api/datasources | jq -r '.[] | .type') )
		for i in ${source[@]}; do
		    if [ "$i" == "loki" ]; then
		        echo 'loki data source exist'
		        exit 0
		    fi
		done

		# 1. add data source
		curl $url/api/datasources \
		-H 'content-type: application/json' \
		--data-raw '{"name":"Loki","type":"loki","access":"proxy","isDefault":false}' \
		--compressed | jq '.datasource' > /datasource.json
		
		cat /datasource.json

		# 2. get data source id
		id=$(cat /datasource.json | jq --raw-output '.id')

		# 3. edit json file .url
		tmp=$(mktemp)
		loki_url=http://loki.logging:3100
		jq --arg a "$loki_url" '.url = $a' /datasource.json > "$tmp" && mv "$tmp" /datasource.json

		cat /datasource.json

		# 4. put data source config
		curl $url/api/datasources/$id \
		-X 'PUT' \
		-H 'content-type: application/json' \
		-d @/datasource.json
		"""#

	_kubectl: base.#Kubectl

	get: bash.#Run & {
		input:  _kubectl.output
		always: true
		env: {
			URL:      url
			NAME:     username
			PASSWORD: password
			WAIT_FOR: strconv.FormatBool(waitFor)
		}
		script: contents: code
		//export: files: "/result": _
	}
}
