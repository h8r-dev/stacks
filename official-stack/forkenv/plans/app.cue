package plans

actions: up: args: {
	service: [{
		name: "forkmain-backend"
		type: "backend"
		url:  "https://github.com/lyzhang1999/forkmain-backend"
		env: [{
			name:  "KEY"
			value: "VALUE"
		}]
	}, {
		name: "forkmain-frontend"
		type: "frontend"
		url:  "https://github.com/lyzhang1999/forkmain-frontend"
		env: [{
			name:  "KEY"
			value: "VALUE"
		}]
	}]
	deploy: {
		name: "forkmain-deploy"
		url:  "https://github.com/lyzhang1999/forkmain-deploy"
	}
	forkenv: {
		name: "bug-fix"
		from: "main"
	}
}
