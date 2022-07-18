package forkmain

#Application: {
	input: {
		name:         string
		appName:      string
		stackName:    string | *"gin-next" // TODO: get stack name and version
		stackVersion: string | *"0.1.0"
		namespace:    string | *"heighliner"
	}

	CRD: {
		apiVersion: "cloud.heighliner.dev/v1alpha1"
		kind:       "Application"
		metadata: {
			namespace: input.namespace
			name:      input.name
			labels: "app.heighliner.dev/name": input.appName
		}
		spec: {
			name: input.appName
			stack: {
				name:    input.stackName
				version: input.stackVersion
			}
		}
	}
}

#Environment: {
	input: {
		name:         string
		envName:      string
		appName:      string
		namespace:    string | *"heighliner"
		chartURL:     string
		chartPath:    string
		envAccessURL: string
		envNamespace: string
	}

	CRD: {
		apiVersion: "cloud.heighliner.dev/v1alpha1"
		kind:       "Environment"
		metadata: {
			namespace: input.namespace
			name:      input.name
			labels: "app.heighliner.dev/name": input.appName
		}
		spec: {
			name:      input.envName
			namespace: input.envNamespace
			chart: {
				version:       "0.0.1"
				url:           input.chartURL
				type:          "github"
				path:          input.chartPath
				valuesFile:    "values.yaml"
				defaultBranch: "main"
			}
			access: previewURL: input.envAccessURL
		}
	}
}

#Repository: {
	input: {
		name:         string
		appName:      string
		namespace:    string | *"heighliner"
		repoName:     string
		repoType:     string | *"github"
		repoURL:      string
		repoProvider: string | *"github"
		organization: string
	}

	CRD: {
		apiVersion: "cloud.heighliner.dev/v1alpha1"
		kind:       "Repository"
		metadata: {
			namespace: input.namespace
			name:      input.name
			labels: "app.heighliner.dev/name": input.appName
		}
		spec: {
			appName: input.appName
			source: {
				name:         input.repoName
				type:         input.repoType
				url:          input.repoURL
				provider:     input.repoProvider
				organization: input.organization
			}
		}
	}
}
