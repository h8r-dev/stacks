package argocd

import (
	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"universe.dagger.io/bash"
	"github.com/h8r-dev/stacks/chain/v5/internal/base"
)

#SetRepoAuth: {
	input: {
		argoVar:            dagger.#Secret
		repositoryPassword: dagger.#Secret | string
		repositoryURL:      string
		waitFor:            bool | *true
	}

	_deps: base.#Image

	_sh: core.#Source & {
		path: "."
		include: ["set-auth.sh"]
	}

	_run: bash.#Run & {
		env: {
			ARGO_VAR:      input.argoVar
			REPO_URL:      input.repositoryURL
			REPO_PASSWORD: input.repositoryPassword
			WAIT_FOR:      "\(input.waitFor)"
		}
		"input": _deps.output
		script: {
			directory: _sh.output
			filename:  "set-auth.sh"
		}
	}
	output: success: _run.success
}

#ApplicationCRD: {
	input: {
		appName:   string
		chartUrl:  string
		envPath:   string
		namespace: string
		cluster:   string | *"https://kubernetes.default.svc"
		project:   string | *"default"
	}
	CRD: {
		apiVersion: "argoproj.io/v1alpha1"
		kind:       "Application"
		metadata: {
			name:      input.appName
			namespace: "argocd"
		}
		spec: {
			destination: {
				namespace: input.namespace
				server:    input.cluster
			}
			project: input.project
			source: {
				helm: valueFiles: [
					input.envPath,
				]
				path:           input.appName
				repoURL:        input.chartUrl
				targetRevision: "HEAD"
			}
			syncPolicy: {
				automated: {}
				syncOptions: ["CreateNamespace=true"]
			}
		}
	}
}
