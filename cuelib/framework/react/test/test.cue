package react

import (
	"dagger.io/dagger"
	"github.com/h8r-dev/cuelib/framework/react"
	"universe.dagger.io/docker"
)

// for test
dagger.#Plan & {
	client: env: APP_NAME: string

	actions: test: {
		appName:  client.env.APP_NAME
		reactApp: react.#Create & {
			name:    appName
			command: "npx create-react-app \(appName)"
		}

		listReact: docker.#Run & {
			input:  reactApp.output
			always: true
			command: {
				name: "sh"
				flags: "-c": """
					cd /root/\(appName) && ls -al
					"""
			}
		}

		nextjs: react.#Create & {
			name:    appName
			command: "echo \(appName) | yarn create next-app --typescript"
		}

		listNextJS: docker.#Run & {
			input:  nextjs.output
			always: true
			command: {
				name: "sh"
				flags: "-c": """
					cd /root/\(appName) && ls -al
					"""
			}
		}
	}
}
