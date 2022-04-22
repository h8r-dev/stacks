package prometheus

import (
	"universe.dagger.io/bash"
	"github.com/h8r-dev/chain/supply/base"
)

#Instance: {
	input: #Input
	do:    bash.#Run & {
		"input": input.image
		env: {
			VERSION:             input.version
			OUTPUT_PATH:         input.helmName
			GRAFANA_DOMAIN:      base.#DefaultDomain.infra.grafana
			ALERTMANAGER_DOMAIN: base.#DefaultDomain.infra.alertManager
			PROMETHEUS_DOMAIN:   base.#DefaultDomain.infra.prometheus
		}
		workdir: "/tmp"
		script: contents: #"""
				helm pull kube-prometheus-stack --repo https://prometheus-community.github.io/helm-charts --version $VERSION
				mkdir -p /scaffold/$OUTPUT_PATH/infra
				tar -zxvf ./kube-prometheus-stack-$VERSION.tgz -C /scaffold/$OUTPUT_PATH/infra
				mv /scaffold/$OUTPUT_PATH/infra/kube-prometheus-stack /scaffold/$OUTPUT_PATH/infra/prometheus

				# set customResource replace mode for argocd: https://github.com/argoproj/argo-cd/issues/8128
				# add annotation for ./prometheus/crds/crd-prometheuses.yaml: argocd.argoproj.io/sync-options: Replace=true
				yq -i '.metadata.annotations += {"argocd.argoproj.io/sync-options": "Replace=true"}' /scaffold/$OUTPUT_PATH/infra/prometheus/crds/crd-prometheuses.yaml
				# enable grafana ingress
				yq -i '.grafana.ingress.enabled = true | .grafana.ingress.hosts[0] = "'$GRAFANA_DOMAIN'"' /scaffold/$OUTPUT_PATH/infra/prometheus/values.yaml
				# enable alertManager ingress
				yq -i '.alertmanager.ingress.enabled = true | .alertmanager.ingress.hosts[0] = "'$ALERTMANAGER_DOMAIN'"' /scaffold/$OUTPUT_PATH/infra/prometheus/values.yaml
				# enable prometheus ingress
				yq -i '.prometheus.ingress.enabled = true | .prometheus.ingress.hosts[0] = "'$PROMETHEUS_DOMAIN'"' /scaffold/$OUTPUT_PATH/infra/prometheus/values.yaml
				# add grafana loki datasource
				yq -i '.grafana.additionalDataSources[0] = {"name": "loki", "type": "loki", "url": "http://loki.loki:3100/", "access": "proxy"}' /scaffold/$OUTPUT_PATH/infra/prometheus/values.yaml
			"""#
	}
	output: #Output & {
		image:   do.output
		success: do.success
	}
}
