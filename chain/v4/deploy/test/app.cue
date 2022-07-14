package test

actions: test: args: {
	middleware: [{
		name: "my_db"
		type: "postgres"
		service: [
			"forkmain-backend",
		]
		url:      "my_db.default.svc"
		username: "admin"
		password: "password"
		setting: storage: "10Gi"
	}, {
		name: "redis"
		type: "redis"
		service: [
			"forkmain-backend",
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
		organization: "h8r-dev"
	}
	image: {
		name:     "github"
		registry: "ghcr.io"
		username: "h8r-dev"
		password: "password"
	}
	application: {
		name:   "forkmain"
		domain: "test.h8r.site"
		service: [{
			name: "forkmain-backend"
			type: "backend"
			image: {
				repository: "ghcr.io/h8r-dev/forkmain-backend/forkmain"
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
				repoUrl: "https://github.com/h8r-dev/forkmain-backend"
				extension: entryFile: "cmd/main.go"
				expose: [{
					port: 80
					paths: [{
						path: "/v1/api"
					}, {
						path: "/v2/api"
					}]
				}]
				env: [{
					name:  "HOST"
					value: "h8r.dev"
				}, {
					name:  "PASSWORD"
					value: "my_secret"
				}, {
					name:  "FORKMAIN_MY_DB_USERNAME"
					value: "admin"
				}, {
					name:  "FORKMAIN_MY_DB_PASSWORD"
					value: "password"
				}, {
					name:  "FORKMAIN_MY_DB_URL"
					value: "my_db.default.svc"
				}]
			}
		}, {
			name: "forkmain-frontend"
			type: "frontend"
			image: {
				repository: "ghcr.io/h8r-dev/forkmain-backend/forkmain"
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
				repoUrl:   "https://github.com/h8r-dev/forkmain-frontend"
				extension: ""
				expose: [{
					port: 80
					paths: [{
						path: "/v1/api"
					}, {
						path: "/v2/api"
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