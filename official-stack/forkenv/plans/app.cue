// This file is definition of app.yaml file
// Use this file to generate app.yaml file
// Use this command to generate app.yaml `cue export app.cue --outfile app.yaml -f`

actions: up: args: {
	application: {
		name:      "test28"
		namespace: "test28-bug-fix"
		domain:    forkenv.name + "-" + application.name + ".h8r.site"
		service: [{
			name: application.name + "-backend"
			type: "backend"
			repo: url: "https://github.com/" + scm.organization + "/" + application.name + "-backend"
			setting: {
				env: [{
					name:  "KEY"
					value: "VALUE"
				}]
				// add any values.yaml key
				extra: key: [{
					name:  "KEY"
					value: "VALUE"
				}]
				fork: {
					from: "main"
					type: "branch"
				}
			}
		}, {
			name: application.name + "-frontend"
			type: "frontend"
			repo: url: "https://github.com/" + scm.organization + "/" + application.name + "-frontend"
			setting: {
				env: [{
					name:  "KEY"
					value: "VALUE"
				}]
				fork: {
					from: "main"
					type: "branch"
				}
			}
		}]
		deploy: {
			name:       application.name + "-deploy"
			url:        "https://github.com/" + scm.organization + "/" + application.name + "-deploy"
			path:       application.name
			valuesFile: "env" + "/" + forkenv.name + "/" + "values.yaml"
		}
	}
	forkenv: {
		name:    "bug-fix"
		cluster: "https://kubernetes.default.svc"
	}
	scm: {
		name:         "github"
		type:         "github"
		organization: "hotdorg"
	}
}
