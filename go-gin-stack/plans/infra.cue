package main

import(
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
    seed: ""
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
        name: "ingress-nginx"
        repository: "https://h8r-helm.pkg.coding.net/release/helm"
        chart: "ingress-nginx"
        namespace: "ingress-nginx"
        action: "installOrUpgrade"
        kubeconfig: helmDeploy.myKubeconfig
        values: #ingressNginxSetting
        wait: true
    }

    targetIngressEndpoint: ingressNginx.#GetIngressEndpoint & {
        kubeconfig: helmDeploy.myKubeconfig
    }
}

installNocalhost: {
    installNamespace: "nocalhost"

    nocalhost: helm.#Chart & {
        name: "nocalhost"
        repository: "https://nocalhost-helm.pkg.coding.net/nocalhost/nocalhost"
        chart: "nocalhost"
        namespace: installNamespace
        action: "installOrUpgrade"
        kubeconfig: helmDeploy.myKubeconfig
        wait: true
        waitFor: installIngress.install
    }

    nocalhostIngress: ingressNginx.#Ingress & {
        name: uri.out + "-nocalhost"
        className: "nginx"
        hostName: nocalhostDomain
        path: "/"
        namespace: installNamespace
        backendServiceName: "nocalhost-web"
        ingressVersion: getIngressVersion.get
    }

    deploy: kubernetes.#Resources & {
        kubeconfig: helmDeploy.myKubeconfig
        manifest: nocalhostIngress.manifestStream
        namespace: installNamespace
        waitFor: installIngress.install
    }

    createH8rIngress: {
        create: h8r.#CreateH8rIngress & {
            name: uri.out + "-nocalhost"
            host: installIngress.targetIngressEndpoint.get
            domain: nocalhostDomain
            port: "80"
        }
    }
}



installLokiStack: {
    installNamespace: "loki"

    lokiStack: helm.#Chart & {
        name: "loki"
        repository: "https://h8r-helm.pkg.coding.net/release/helm"
        chart: "loki-stack"
        action: "installOrUpgrade"
        namespace: "loki"
        kubeconfig: helmDeploy.myKubeconfig
        wait: true
        waitFor: installIngress.install
    }

    initIngressNginxDashboard: grafana.#CreateIngressDashboard & {
        url: grafanaDomain
        username: "admin"
        password: installLokiStack.grafanaIngressToTargetCluster.grafanaSecret.get
        waitGrafana: lokiStack
    }

    initNodeExporterDashboard: grafana.#CreateNodeExporterDashboard & {
        url: grafanaDomain
        username: "admin"
        password: installLokiStack.grafanaIngressToTargetCluster.grafanaSecret.get
        waitGrafana: lokiStack
    }

    grafanaIngressToTargetCluster: {
        ingress: ingressNginx.#Ingress & {
            name: uri.out + "-grafana"
            className: "nginx"
            hostName: grafanaDomain
            path: "/"
            namespace: installNamespace
            backendServiceName: "loki-grafana"
            ingressVersion: getIngressVersion.get
        }

        deploy: kubernetes.#Resources & {
            kubeconfig: helmDeploy.myKubeconfig
            manifest: ingress.manifestStream
            namespace: installNamespace
            waitFor: installIngress.install
        }

        createH8rIngress: {
            create: h8r.#CreateH8rIngress & {
                name: uri.out + "-grafana"
                host: installIngress.targetIngressEndpoint.get
                domain: grafanaDomain
                port: "80"
            }
        }

        // Grafana secret, username admin
        grafanaSecret: loki.#GetLokiSecret & {
            kubeconfig: helmDeploy.myKubeconfig
        }
    }

    prometheusIngressToTargetCluster: {
        ingress: ingressNginx.#Ingress & {
            name: uri.out + "-prometheus"
            className: "nginx"
            hostName: prometheusDomain
            path: "/"
            namespace: installNamespace
            backendServiceName: "loki-prometheus-server"
            ingressVersion: getIngressVersion.get
        }

        deploy: kubernetes.#Resources & {
            kubeconfig: helmDeploy.myKubeconfig
            manifest: ingress.manifestStream
            namespace: installNamespace
            waitFor: installIngress.install
        }

        createH8rIngress: {
            create: h8r.#CreateH8rIngress & {
                name: uri.out + "-prometheus"
                host: installIngress.targetIngressEndpoint.get
                domain: prometheusDomain
                port: "80"
            }
        }
    }

    alertmanagerIngressToTargetCluster: {
        ingress: ingressNginx.#Ingress & {
            name: uri.out + "-alertmanager"
            className: "nginx"
            hostName: alertmanagerDomain
            path: "/"
            namespace: installNamespace
            backendServiceName: "loki-prometheus-alertmanager"
            ingressVersion: getIngressVersion.get
        }

        deploy: kubernetes.#Resources & {
            kubeconfig: helmDeploy.myKubeconfig
            manifest: ingress.manifestStream
            namespace: installNamespace
            waitFor: installIngress.install
        }

        createH8rIngress: {
            create: h8r.#CreateH8rIngress & {
                name: uri.out + "-alertmanager"
                host: installIngress.targetIngressEndpoint.get
                domain: alertmanagerDomain
                port: "80"
            }
        }
    }
}