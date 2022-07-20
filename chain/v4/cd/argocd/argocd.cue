package argocd

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
