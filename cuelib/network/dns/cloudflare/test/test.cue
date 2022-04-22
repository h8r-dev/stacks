package cloudflare

import (
	"dagger.io/dagger"
	"github.com/h8r-dev/stacks/cuelib/network/dns/cloudflare"
)

// for test
dagger.#Plan & {
	client: env: {
		ZONE_ID:        dagger.#Secret
		API_TOKEN:      dagger.#Secret
		RECORD_TYPE:    string
		RECORD_NAME:    string
		RECORD_CONTENT: string
	}
	actions: test: cloudflare.#CreateDNSRecord & {
		zoneID:   client.env.ZONE_ID
		apiToken: client.env.API_TOKEN
		record: {
			type:    client.env.RECORD_TYPE
			name:    client.env.RECORD_NAME
			content: client.env.RECORD_CONTENT
		}
	}
}
