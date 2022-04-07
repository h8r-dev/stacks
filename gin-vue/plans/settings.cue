package main

import (
	"github.com/h8r-dev/cuelib/utils/random"
)

// random uri
uri: random.#String

// Application install namespace
appInstallNamespace: "production"

// App domain prefix
appDomain: uri.output + ".go-gin.h8r.app"

// App domain
//showAppDomain: appInstallNamespace + "." + appDomain

// Dev domain
devDomain: ".dev.go-gin.h8r.app"

// Infra domain
infraDomain: ".stack.h8r.io"

// Nocalhost URL
nocalhostDomain: uri.output + ".nocalhost" + infraDomain

// ArgoCD URL
argocdDomain: uri.output + ".argocd" + infraDomain

// Grafana URL
grafanaDomain: uri.output + ".grafana" + infraDomain

// Prometheus URL
prometheusDomain: uri.output + ".prom" + infraDomain

// Alertmanager URL
alertmanagerDomain: uri.output + ".alert" + infraDomain

// Nocalhost
nocalhostDefaultUsername: "admin@admin.com"
nocalhostDefaultPassword: "123456"

// ArgoCD namespace
argoCDNamespace:       "argocd"
argoCDDefaultUsername: "admin"

ingressNginxNamespace: "ingress-nginx"

// Monitoring and logging
lokiNamespace:          "logging"
prometheusNamespace:    "monitoring"
prometheusReleaseName:  "prometheus"
grafanaDefaultUsername: "admin"

ingressNginxSetting: #"""
	controller:
	  service:
	    type: LoadBalancer
	  metrics:
	    enabled: true
	  podAnnotations:
	    prometheus.io/scrape: "true"
	    prometheus.io/port: "10254"
	"""#

ingressNginxUpgradeSetting: #"""
	controller:
	  service:
	    type: LoadBalancer
	  metrics:
	    enabled: true
	    serviceMonitor:
	      enabled: true
	      additionalLabels:
	        release: "prometheus"
	  podAnnotations:
	    prometheus.io/scrape: "true"
	    prometheus.io/port: "10254"
	"""#
