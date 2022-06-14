package argocd

import (
	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"universe.dagger.io/bash"

	"github.com/h8r-dev/stacks/cuelib/internal/base"
)

#Input: {
	name:               string
	repositoryPassword: dagger.#Secret
	repositoryURL:      string
	appPath:            string
	password:           string | dagger.#Secret
	waitFor:            bool | *true
	domain:             base.#DefaultDomain
	// Helm set values, such as "key1=value1,key2=value2"
	set: string | *null
}

#CreateApp: {
	input: #Input

	_deps: base.#Image

	_sh: core.#Source & {
		path: "."
		include: ["create-app.sh"]
	}

	_run: bash.#Run & {
		env: {
			ARGO_SERVER:   base.#DefaultInternalDomain.infra.argocd
			ARGO_URL:      input.domain.infra.argocd
			ARGO_USERNAME: "admin"
			if input.set != null {
				HELM_SET: input.set
			}
			APP_NAMESPACE: input.domain.application.productionNamespace
			APP_SERVER:    "https://kubernetes.default.svc"
			PASSWORD:      input.password
			REPO_URL:      input.repositoryURL
			REPO_PASSWORD: input.repositoryPassword
			APP_NAME:      input.name
			APP_PATH:      input.appPath
			WAIT_FOR:      "\(input.waitFor)"
		}
		"input": _deps.output
		script: {
			directory: _sh.output
			filename:  "create-app.sh"
		}
	}
}
