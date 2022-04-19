package main

import (
	"universe.dagger.io/bash"
	"encoding/yaml"
	"github.com/h8r-dev/stacks/cuelib/utils/base"
)

// output cue struct
#OutputStruct: {
	application: {
		// application domain
		domain: string
		// ingress endpoint
		ingress: string
	}

	// git repository
	repository: {
		frontend: string
		backend:  string
		deploy:   string
	}

	prometheus: domain: string

	grafana: {
		domain:   string
		username: string
		password: string
	}

	alertManager: domain: string

	argocd: {
		domain:   string
		username: string
		password: string
	}

	nocalhost: {
		domain:   string
		username: string
		password: string
	}

	outputStruct: {
		"application": {
			domain:  application.domain
			ingress: application.ingress
		}
		"repository": {
			backend:  repository.backend
			frontend: repository.frontend
			deploy:   repository.deploy
		}
		infra: {
			[
				{
					type: "prometheus"
					url:  prometheus.domain
				},
				{
					type:     "grafana"
					url:      grafana.domain
					username: grafana.username
					password: grafana.password
				},
				{
					type: "alertManager"
					url:  alertManager.domain
				},
				{
					type:     "argoCD"
					url:      argocd.domain
					username: argocd.username
					password: argocd.password
				},
				{
					type:     "nocalhost"
					url:      nocalhost.domain
					username: nocalhost.username
					password: nocalhost.password
				},
			]
		}
	}

	outputYaml: yaml.Marshal(outputStruct)

	_inputImage: base.#Kubectl

	run: bash.#Run & {
		input: _inputImage.output
		script: contents: #"""
			    printf '\#(outputYaml)' > /output.yaml
			"""#
		export: files: "/output.yaml": string
	}

	output: run.export.files."/output.yaml"
}
