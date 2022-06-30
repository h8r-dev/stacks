package next

import (
	"dagger.io/dagger"
	"universe.dagger.io/docker"
	"github.com/h8r-dev/stacks/chain/internal/framework/react/next"
)

dagger.#Plan & {
	client: {

	}

	actions: test: {
		appName: "test-app-name"
		image:   next.#Create & {
			name:       appName
			typescript: true
		}
		run: docker.#Run & {
			input:  image.output
			always: true
			command: {
				name: "sh"
				flags: "-c": """
					cd /root/\(appName)
					ls -al
					cat next.config.js
					"""
			}
		}
	}
}
