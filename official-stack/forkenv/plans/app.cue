package plans

actions: up: args: {
	application: name: "<app_name>"
	service: [{
		name: "<app_name>-backend"
		type: "backend"
		url:  "https://github.com/<git_org>/<app_name>-backend"
		env: [{
			name:  "KEY"
			value: "VALUE"
		}]
		extra: env2: [{
			name:  "KEY2"
			value: "VALUE2"
		}, {
			name:  "KEY3"
			value: "VALUE3"
		}]
	}, {
		name: "<app_name>-frontend"
		type: "frontend"
		url:  "https://github.com/<git_org>/<app_name>-frontend"
		env: [{
			name:  "KEY"
			value: "VALUE"
		}]
	}]
	deploy: {
		name: "<app_name>-deploy"
		url:  "https://github.com/<git_org>/<app_name>-deploy"
	}
	forkenv: {
		name:   "bug-fix"
		from:   "main"
		domain: "bug-fix-<app_name>.h8r.site"
	}
	scm: {
		name:         "github"
		type:         "github"
		organization: "<git_org>"
	}
}
