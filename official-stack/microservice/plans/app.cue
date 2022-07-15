package plans

actions: up: args: {
	middleware: [{
		name: "my_db"
		type: "postgres"
		service: [
			"hello-world37-backend",
		]
		url:      "my_db.default.svc"
		username: "admin"
		password: "password"
		setting: storage: "10Gi"
	}, {
		name: "redis"
		type: "redis"
		service: [
			"hello-world37-backend",
		]
		url:      "redis.default.svc"
		username: "admin"
		password: "password"
		setting: storage: "10Gi"
	}]
	scm: {
		name:         "github"
		type:         "github"
		token:        "ghp_xxxxxx"
		organization: "lyzhang1999"
	}
	image: {
		name:     "github"
		registry: "ghcr.io"
		username: "lyzhang1999"
		password: "password"
	}
	application: {
		name:   "hello-world37"
		domain: "hello-world37.h8r.site"
		deploy: {
			name:       "hello-world37-deploy"
			url:        "https://github.com/lyzhang1999/hello-world37-deploy"
			visibility: "private"
		}
		service: [{
			name: "hello-world37-backend"
			type: "backend"
			repo: {
				url:        "https://github.com/lyzhang1999/hello-world37-backend"
				visibility: "private"
			}
			image: {
				repository: "ghcr.io/lyzhang1999/hello-world37-backend"
				tag:        ""
			}
			language: {
				name:    "golang"
				version: "1.8"
			}
			framework: "gin"
			build:     "dockerfile"
			ci:        "github"
			command: {
				build: ""
				run:   ""
				debug: ""
			}
			scaffold: true
			setting: {
				extension: entryFile: "cmd/main.go"
				expose: [{
					port: 80
					paths: [{
						path:    "/api"
						rewrite: true
					}, {
						path:    "/v2/api"
						rewrite: false
					}]
				}]
				env: [{
					name:  "HOST"
					value: "h8r.dev"
				}, {
					name:  "PASSWORD"
					value: "my_secret"
				}, {
					name:  "MY_DB_USERNAME"
					value: "admin"
				}, {
					name:  "MY_DB_PASSWORD"
					value: "password"
				}, {
					name:  "MY_DB_URL"
					value: "my_db.default.svc"
				}]
			}
		}, {
			name: "hello-world37-frontend"
			type: "frontend"
			repo: {
				url:        "https://github.com/lyzhang1999/hello-world37-frontend"
				visibility: "private"
			}
			image: {
				repository: "ghcr.io/lyzhang1999/hello-world37-frontend"
				tag:        ""
			}
			scaffold: true
			language: {
				name:    "typescript"
				version: "1.8"
			}
			framework: "nextjs"
			build:     "dockerfile"
			ci:        "github"
			setting: {
				extension: ""
				expose: [{
					port: 80
					paths: [{
						path:    "/"
						rewrite: false
					}]
				}]
				env: [{
					name:  "HOST"
					value: "h8r.dev"
				}, {
					name:  "PASSWORD"
					value: "my_secret"
				}]
			}
		}]
	}
}
