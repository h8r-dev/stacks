package plans

actions: up: args: {
	middleware: [{
		name: "my_db"
		type: "postgres"
		service: [
			"<app_name>-backend",
		]
		url:      "my_db.default.svc"
		username: "admin"
		password: "password"
		setting: storage: "10Gi"
	}, {
		name: "redis"
		type: "redis"
		service: [
			"<app_name>-backend",
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
		organization: "<git_org>"
	}
	image: {
		name:     "github"
		registry: "ghcr.io"
		username: "<git_org>"
		password: "password"
	}
	application: {
		name:   "<app_name>"
		domain: "<app_name>.h8r.site"
		deploy: {
			name: "<app_name>-deploy"
			url:  "https://github.com/<git_org>/<app_name>-deploy"
		}
		service: [{
			name: "<app_name>-backend"
			type: "backend"
			repo: {
				url:        "https://github.com/<git_org>/<app_name>-backend"
				visibility: "private"
			}
			image: {
				repository: "ghcr.io/<git_org>/<app_name>-backend"
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
						path: "/api"
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
			name: "<app_name>-frontend"
			type: "frontend"
			repo: {
				url:        "https://github.com/<git_org>/<app_name>-frontend"
				visibility: "private"
			}
			image: {
				repository: "ghcr.io/<git_org>/<app_name>-frontend"
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
						path: "/"
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
