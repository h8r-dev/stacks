package certmanager

import (
	"dagger.io/dagger"
	"github.com/h8r-dev/stacks/chain/internal/secure/certmanager"
)

// for test
dagger.#Plan & {
	client: {
		env: {
			KUBECONFIG: string
			API_TOKEN:  dagger.#Secret
		}
		commands: kubeconfig: {
			name: "cat"
			args: ["\(env.KUBECONFIG)"]
			stdout: dagger.#Secret
		}
	}
	actions: test: {
		install: certmanager.#InstallCertManager & {
			kubeconfig: client.commands.kubeconfig.stdout
		}

		declareIssuer: certmanager.#ACMEIssuer & {
			kubeconfig: client.commands.kubeconfig.stdout
			email:      "vendor@h8r.io"
			apiToken:   client.env.API_TOKEN
			waitFor:    install.success
		}

		declareCert: certmanager.#ACMECert & {
			kubeconfig: client.commands.kubeconfig.stdout
			waitFor:    declareIssuer.success
			namespace:  "h8r-system"
			name:       "heighliner-app"
			commonName: "h8r.app"
			domains: [
				"h8r.app",
				"*.h8r.app",
				"*.dev.h8r.app",
				"*.prod.h8r.app",
				"*.test.h8r.app",
				"*.staging.h8r.app",
				"*.alpha.h8r.app",
				"*.beta.h8r.app",
			]
		}
	}
}
