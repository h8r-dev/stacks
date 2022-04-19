package next

import (
	"dagger.io/dagger"
	"github.com/h8r-dev/stacks/cuelib/framework/react/next"
	"universe.dagger.io/docker"
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
