package cloudflare

import (
	"encoding/json"
	"dagger.io/dagger"
	"universe.dagger.io/alpine"
	"universe.dagger.io/bash"
)

#CreateDNSRecord: {

	// record
	record: {
		type: string | *"A"
		// domain to resolve, for example: heighliner.pro,xxx.heighliner.pro
		name: string
		// content, for example: A record: 127.0.0.1, CNAME: heighliner.dev
		content:  string
		ttl:      int | *600
		priority: int | *10
		proxied:  bool | *false
	}

	zoneID:   dagger.#Secret
	apiToken: dagger.#Secret

	base: alpine.#Build & {
		packages: {
			bash: {}
			curl: {}
		}
	}

	run: bash.#Run & {
		input:   base.output
		workdir: "/root"
		always:  true
		env: {
			API_TOKEN: apiToken
			ZONE_ID:   zoneID
			JSON:      json.Marshal(record)
		}

		script: contents: #"""
			curl -v "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
			    -H "Authorization: Bearer $API_TOKEN" \
			    -H "Content-Type: application/json" \
			    --data $JSON
			"""#
	}
}
