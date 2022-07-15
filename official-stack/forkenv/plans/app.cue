package plans

actions: up: args: {
	application: name: "hello-world37"
	service: [{
		name: "hello-world37-backend"
		type: "backend"
		url:  "https://github.com/lyzhang1999/hello-world37-backend"
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
		name: "hello-world37-frontend"
		type: "frontend"
		url:  "https://github.com/lyzhang1999/hello-world37-frontend"
		env: [{
			name:  "KEY"
			value: "VALUE"
		}]
	}]
	deploy: {
		name: "hello-world37-deploy"
		url:  "https://github.com/lyzhang1999/hello-world37-deploy"
	}
	forkenv: {
		name:   "bug-fix1"
		from:   "main"
		domain: "bug-fix-hello-world37.h8r.site"
	}
	scm: {
		name:         "github"
		type:         "github"
		organization: "lyzhang1999"
	}
}
