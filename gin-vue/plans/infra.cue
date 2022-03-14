package main

import (
	kubernetes "github.com/h8r-dev/cuelib/deploy/kubectl"
	"github.com/h8r-dev/cuelib/deploy/helm"
	"alpha.dagger.io/random"
	ingressNginx "github.com/h8r-dev/cuelib/infra/ingress"
	"github.com/h8r-dev/cuelib/infra/h8r"
	"github.com/h8r-dev/cuelib/infra/loki"
	"github.com/h8r-dev/cuelib/monitoring/grafana"
	"github.com/h8r-dev/go-gin-stack/plans/check"
)

uri: random.#String & {
	seed:   ""
	length: 6
}

// Infra domain
infraDomain: ".stack.h8r.io"

// Nocalhost URL
nocalhostDomain: uri.out + ".nocalhost" + infraDomain @dagger(output)

// Grafana URL
grafanaDomain: uri.out + ".grafana" + infraDomain @dagger(output)

// Prometheus URL
prometheusDomain: uri.out + ".prom" + infraDomain @dagger(output)

// Alertmanager URL
alertmanagerDomain: uri.out + ".alert" + infraDomain @dagger(output)

getIngressVersion: check.#GetIngressVersion & {
	kubeconfig: helmDeploy.myKubeconfig
}

installIngress: {
	install: helm.#Chart & {
		name:       "ingress-nginx"
		repository: "https://h8r-helm.pkg.coding.net/release/helm"
		chart:      "ingress-nginx"
		namespace:  "ingress-nginx"
		action:     "installOrUpgrade"
		kubeconfig: helmDeploy.myKubeconfig
		values:     #ingressNginxSetting
		wait:       true
	}

	targetIngressEndpoint: ingressNginx.#GetIngressEndpoint & {
		kubeconfig: helmDeploy.myKubeconfig
	}

	// wait for prometheus operator ready then upgrade ingress nginx metric
	forWait: kubernetes.#WaitFor & {
		kubeconfig: helmDeploy.myKubeconfig
		worklaod:   "ServiceMonitor"
	}

	// upgrade ingress nginx for serviceMonitor
	upgrade: helm.#Chart & {
		name:       "ingress-nginx"
		repository: "https://h8r-helm.pkg.coding.net/release/helm"
		chart:      "ingress-nginx"
		namespace:  "ingress-nginx"
		action:     "installOrUpgrade"
		kubeconfig: helmDeploy.myKubeconfig
		values:     #ingressNginxUpgradeSetting
		wait:       true
		waitFor:    installIngress.forWait
	}
}

installNocalhost: {
	installNamespace: "nocalhost"

	nocalhost: helm.#Chart & {
		name:       "nocalhost"
		repository: "https://nocalhost-helm.pkg.coding.net/nocalhost/nocalhost"
		chart:      "nocalhost"
		namespace:  installNamespace
		action:     "installOrUpgrade"
		kubeconfig: helmDeploy.myKubeconfig
		wait:       true
		waitFor:    installIngress.install
	}

	nocalhostIngress: ingressNginx.#Ingress & {
		name:               uri.out + "-nocalhost"
		className:          "nginx"
		hostName:           nocalhostDomain
		path:               "/"
		namespace:          installNamespace
		backendServiceName: "nocalhost-web"
		ingressVersion:     getIngressVersion.get
	}

	deploy: kubernetes.#Resources & {
		kubeconfig: helmDeploy.myKubeconfig
		manifest:   nocalhostIngress.manifestStream
		namespace:  installNamespace
		waitFor:    installIngress.install
	}

	createH8rIngress: create: h8r.#CreateH8rIngress & {
		name:   uri.out + "-nocalhost"
		host:   installIngress.targetIngressEndpoint.get
		domain: nocalhostDomain
		port:   "80"
	}
}

installPrometheusStack: {
	releaseName:      "prometheus"
	installNamespace: "monitoring"

	kubePrometheus: helm.#Chart & {
		name:       installPrometheusStack.releaseName
		repository: "https://prometheus-community.github.io/helm-charts"
		chart:      "kube-prometheus-stack"
		action:     "installOrUpgrade"
		namespace:  installPrometheusStack.installNamespace
		kubeconfig: helmDeploy.myKubeconfig
		wait:       true
		waitFor:    installIngress.install
	}

	// Grafana secret, username admin
	grafanaSecret: loki.#GetLokiSecret & {
		secretName: installPrometheusStack.releaseName + "-grafana"
		kubeconfig: helmDeploy.myKubeconfig
		namespace:  installPrometheusStack.installNamespace
	}

	initIngressNginxDashboard: grafana.#CreateIngressDashboard & {
		url:         grafanaDomain
		username:    "admin"
		password:    installPrometheusStack.grafanaSecret.get
		waitGrafana: installPrometheusStack.kubePrometheus
	}

	initLokiDataSource: grafana.#CreateLokiDataSource & {
		url:         grafanaDomain
		username:    "admin"
		password:    installPrometheusStack.grafanaSecret.get
		waitGrafana: installPrometheusStack.kubePrometheus
		waitLoki:    installLokiStack.lokiStack
	}

	grafanaIngressToTargetCluster: {
		ingress: ingressNginx.#Ingress & {
			name:               uri.out + "-grafana"
			className:          "nginx"
			hostName:           grafanaDomain
			path:               "/"
			namespace:          installPrometheusStack.installNamespace
			backendServiceName: installPrometheusStack.releaseName + "-grafana"
			ingressVersion:     getIngressVersion.get
		}

		deploy: kubernetes.#Resources & {
			kubeconfig: helmDeploy.myKubeconfig
			manifest:   ingress.manifestStream
			namespace:  installPrometheusStack.installNamespace
			waitFor:    installIngress.install
		}

		createH8rIngress: create: h8r.#CreateH8rIngress & {
			name:   uri.out + "-grafana"
			host:   installIngress.targetIngressEndpoint.get
			domain: grafanaDomain
			port:   "80"
		}
	}

	prometheusIngressToTargetCluster: {
		ingress: ingressNginx.#Ingress & {
			name:               uri.out + "-prometheus"
			className:          "nginx"
			hostName:           prometheusDomain
			path:               "/"
			namespace:          installPrometheusStack.installNamespace
			backendServiceName: "prometheus-operated"
			backendServicePort: 9090
			ingressVersion:     getIngressVersion.get
		}

		deploy: kubernetes.#Resources & {
			kubeconfig: helmDeploy.myKubeconfig
			manifest:   ingress.manifestStream
			namespace:  installPrometheusStack.installNamespace
			waitFor:    installIngress.install
		}

		createH8rIngress: create: h8r.#CreateH8rIngress & {
			name:   uri.out + "-prometheus"
			host:   installIngress.targetIngressEndpoint.get
			domain: prometheusDomain
			port:   "80"
		}
	}

	alertmanagerIngressToTargetCluster: {
		ingress: ingressNginx.#Ingress & {
			name:               uri.out + "-alertmanager"
			className:          "nginx"
			hostName:           alertmanagerDomain
			path:               "/"
			namespace:          installPrometheusStack.installNamespace
			backendServiceName: "alertmanager-operated"
			backendServicePort: 9093
			ingressVersion:     getIngressVersion.get
		}

		deploy: kubernetes.#Resources & {
			kubeconfig: helmDeploy.myKubeconfig
			manifest:   ingress.manifestStream
			namespace:  installPrometheusStack.installNamespace
			waitFor:    installIngress.install
		}

		createH8rIngress: create: h8r.#CreateH8rIngress & {
			name:   uri.out + "-alertmanager"
			host:   installIngress.targetIngressEndpoint.get
			domain: alertmanagerDomain
			port:   "80"
		}
	}

}

installLokiStack: {
	installNamespace: "logging"

	lokiStack: helm.#Chart & {
		name:       "loki"
		repository: "https://grafana.github.io/helm-charts"
		chart:      "loki-stack"
		action:     "installOrUpgrade"
		namespace:  installLokiStack.installNamespace
		kubeconfig: helmDeploy.myKubeconfig
		wait:       true
		waitFor:    installIngress.install
	}

	// initNodeExporterDashboard: grafana.#CreateNodeExporterDashboard & {
	//     url: grafanaDomain
	//     username: "admin"
	//     password: installLokiStack.grafanaIngressToTargetCluster.grafanaSecret.get
	//     waitGrafana: lokiStack
	// }
}
