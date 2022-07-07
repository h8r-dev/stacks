action: up: args: {
	middleware: [{
		name: "my_db" // 默认，不提供命名修改
		type: "postgres"
		url:  "my_db.default.svc"
		username:
			"admin", password:
			"password", setting: storage:
			"10Gi"
	}, {
		name: "redis"
		type: "redis"
		url:  "redis.default.svc"
		username:
			"admin", password:
			"password", setting: storage:
			"10Gi"
	}], scm: [{
		name:  "github"
		type:  "github"
		token: "ghp_xxxxxx"
		organization:
			"h8r-dev"
	}], application: {
		name: "forkmain"
		service: [{
			name: "forkmain-backend"
			type: "backend"
			language: {
				name:
					"golang", version:
					1.8
			}, framework:
				"gin", build:
				"dockerfile" // default
			ci: "github"
			// 默认
			command: {// 预留
				build: ""
				run:   ""
				debug: ""
			}
			scaffold: false
			// true 代表创建仓库，false 代表从已有仓库创建
			setting: {repoUrl: "https://github.com/h8r-dev/forkmain-backend"

				extension: entryFile: "cmd/main.go"
				expose: [{
					// 嵌套数组在 cue/shell 里面是否会很难处理？
					port: 80, paths: [{
						path: "/v1/api"
					}, {
						path:
							"/v2/api"
					}]
				}]
				env: [{
					name:  "HOST"
					value: "h8r.dev"
				}, {
					name: "PASSWORD"
					value:
						"my_secret"
				}, {
					name:
						"FORKMAIN_MY_DB_USERNAME" // auto inject
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
			type: "frontend", scaffold: false
			// true 代表创建仓库，false 代表从以有的仓库创建
			language: {
					name: "typescript", version: 1.8
			}, framework: "nextjs", build:
					"dockerfile" // default
			ci:           "github"
			setting: {
				expose: [{
					// 嵌套数组在 cue/shell 里面是否会很难处理？
					port: 80
					paths: [{
						path: "/v1/api"
					}, {
						path: "/v2/api"
					}]
				}], env: [{
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
