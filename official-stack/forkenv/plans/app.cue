package plans

actions: up: args: {
	application: name: "hello-world36"
	service: [{
		name: "hello-world36-backend"
		type: "backend"
		url:  "https://github.com/lyzhang1999/hello-world36-backend"
	}, {
		name: "hello-world36-frontend"
		type: "frontend"
		url:  "https://github.com/lyzhang1999/hello-world36-frontend"
		env: [{
			name:  "KEY2"
			value: "VALUE2"
		}, {
			name:  "KEY3"
			value: "VALUE3"
		}]
	}]
	deploy: {
		name: "hello-world36-deploy"
		url:  "https://github.com/lyzhang1999/hello-world36-deploy"
	}
	forkenv: {
		name:   "fm-bug-fix9"
		from:   "main"
		domain: "bug-fix.hello-world36.h8r.site"
	}
	scm: {
		name:         "github"
		type:         "github"
		token:        ""
		organization: "lyzhang1999"
	}
}
