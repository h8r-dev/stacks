package var

// TODO: adapt to different platforms
#Generator: {
	input: {
		applicationName: string
		domain:          string
		networkType:     string
		organization:    string
		scmType:         string | *"github"
		frameworks: [...]
		addons: [...]
	}
	_args: {
		scmType:         input.scmType
		applicationName: input.applicationName
		organization:    input.organization
	}
	for f in input.frameworks {
		(f.name): _#repository & {
			type: _args.scmType
			input: {
				prefix:       _args.applicationName
				suffix:       _frameworkType[(f.name)]
				organization: _args.organization
			}
		}
	}

	deploy: _#repository & {
		type: input.scmType
		"input": {
			prefix:       input.applicationName
			suffix:       "deploy"
			organization: input.organization
		}
	}
}

_#repository: {
	type: "github"
	input: {
		prefix:       string
		suffix:       string
		organization: string
	}
	repoName:      "\(input.prefix)-\(input.suffix)"
	repoURL:       "https://github.com/\(input.organization)/\(repoName)"
	imageURL:      "ghcr.io/\(input.organization)/\(repoName)"
	frameworkType: "\(input.suffix)"
}

_frameworkType: {
	gin:  "backend"
	next: "frontend"
}
