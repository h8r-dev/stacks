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
		services: [...]
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
				suffix:       frameworkType[(f.name)]
				organization: _args.organization
			}
		}
	}

	msvcs: {
		for s in input.services {
			(s.name): _#serviceRepository & {
				type: _args.scmType
				input: {
					name:         s.repository
					organization: _args.organization
				}
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

_#serviceRepository: {
	type: "github"
	input: {
		name:         string
		organization: string
	}
	repoName: input.name
	repoURL:  "https://github.com/\(input.organization)/\(repoName)"
	imageURL: "ghcr.io/\(input.organization)/\(repoName)"
}

frameworkType: {
	gin:  "backend"
	next: "frontend"
}
