package plans

import (
	"dagger.io/dagger"
	"github.com/h8r-dev/stacks/cuelib/stacks"
)

dagger.#Plan & {
	client: {
		commands: kubeconfig: {
			name: "cat"
			args: [env.KUBECONFIG]
			stdout: dagger.#Secret
		}
		env: {
			KUBECONFIG: string
			APP_NAME:   string
		}
	}
	actions: {
		up: stacks.#Install & {
			args: {
				name:        client.env.APP_NAME
				domain:      "\(name).h8r.site"
				githubToken: "ghp_WAFSFSGTJHasdsadwdsadwad"
				frameworks: [
					{
						name: "gin"
					},
					{
						name: "next"
					},
				]
				addons: [
					{
						name: "nocalhost"
					},
					{
						name: "prometheus"
					},
				]
			}
		}
	}
}
