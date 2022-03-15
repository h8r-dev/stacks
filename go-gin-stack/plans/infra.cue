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
    "github.com/h8r-dev/cuelib/deploy/argocd"
)

uri: random.#String & {
    seed: ""
    length: 6
}

// Infra domain
infraDomain: ".stack.h8r.io"

// Nocalhost URL
nocalhostDomain: uri.out + ".nocalhost" + infraDomain @dagger(output)

// ArgoCD URL
argocdDomain: uri.out + ".argocd" + infraDomain @dagger(output)

// Grafana URL
grafanaDomain: uri.out + ".grafana" + infraDomain @dagger(output)

// Prometheus URL
prometheusDomain: uri.out + ".prom" + infraDomain @dagger(output)

// Alertmanager URL
alertmanagerDomain: uri.out + ".alert" + infraDomain @dagger(output)

// ArgoCD namespace
argoCDNamespace: "argocd"

// ArgoCD application deploy namespace
argoApplicationNamespace: appInstallNamespace

getIngressVersion: check.#GetIngressVersion & {
    kubeconfig: myKubeconfig
}

installArgoCD: {
    install: argocd.#InstallArgoCD & {
        kubeconfig: myKubeconfig
        namespace: argoCDNamespace
        url: "https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"
        waitFor: installIngress.install
    }

    argoCDIngress: ingressNginx.#Ingress & {
        name: uri.out + "-argocd"
        className: "nginx"
        hostName: argocdDomain
        path: "/"
        namespace: argoCDNamespace
        backendServiceName: "argocd-server"
        backendServicePort: 80
        ingressVersion: getIngressVersion.get
    }

    deploy: kubernetes.#Resources & {
        kubeconfig: myKubeconfig
        manifest: argoCDIngress.manifestStream
        namespace: argoCDNamespace
        waitFor: install.install
    }

    createH8rIngress: {
        create: h8r.#CreateH8rIngress & {
            name: uri.out + "-argocd"
            host: installIngress.targetIngressEndpoint.get
            domain: argocdDomain
            port: "80"
        }
    }
    
    argocdConfig: argocd.#Config & {
        version: "v2.3.1"
        server:  argocdDomain
        basicAuth: {
            username: "admin"
            password: install.install
        }
    }

    createApp: argocd.#App & {
        config: argocdConfig
        name:   initRepo.applicationName
        repo:   initHelmRepo.gitUrl
        namespace: argoApplicationNamespace
        path: "."
        helmSet: "ingress.hosts[0].host=" + appDomain + ",ingress.hosts[0].paths[0].path=/,ingress.hosts[0].paths[0].pathType=ImplementationSpecific"
    }

    // create image pull secret for argocd
    createImagePullSecret: kubernetes.#CreateImagePullSecret & {
        kubeconfig: myKubeconfig
        username: initRepo.organization
        password: initRepo.accessToken
        namespace: argoApplicationNamespace
    }
}

installIngress: {
    install: helm.#Chart & {
        name: "ingress-nginx"
        repository: "https://h8r-helm.pkg.coding.net/release/helm"
        chart: "ingress-nginx"
        namespace: "ingress-nginx"
        action: "installOrUpgrade"
        kubeconfig: myKubeconfig
        values: #ingressNginxSetting
        wait: true
    }

    targetIngressEndpoint: ingressNginx.#GetIngressEndpoint & {
        kubeconfig: myKubeconfig
    }

    // wait for prometheus operator ready then upgrade ingress nginx metric
    forWait: kubernetes.#WaitFor & {
        kubeconfig: myKubeconfig
        worklaod: "ServiceMonitor"
    }

    // upgrade ingress nginx for serviceMonitor
    upgrade: helm.#Chart & {
        name: "ingress-nginx"
        repository: "https://h8r-helm.pkg.coding.net/release/helm"
        chart: "ingress-nginx"
        namespace: "ingress-nginx"
        action: "installOrUpgrade"
        kubeconfig: myKubeconfig
        values: #ingressNginxUpgradeSetting
        wait: true
        waitFor: {
            "/waitinstall": from: installIngress.install
            "/waitprometheus": from: forWait
        }
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
        kubeconfig: myKubeconfig
        wait: true
        waitFor: {
            "/wait": from: installIngress.install
        }
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
        kubeconfig: myKubeconfig
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

installPrometheusStack: {
    releaseName: "prometheus"
    installNamespace: "monitoring"

    kubePrometheus: helm.#Chart & {
        name: installPrometheusStack.releaseName
        repository: "https://prometheus-community.github.io/helm-charts"
        chart: "kube-prometheus-stack"
        action: "installOrUpgrade"
        namespace: installPrometheusStack.installNamespace
        kubeconfig: myKubeconfig
        wait: true
        waitFor: {
            "/wait": from: installIngress.install
        }
    }

    // Grafana secret, username admin
    grafanaSecret: loki.#GetLokiSecret & {
        secretName: installPrometheusStack.releaseName + "-grafana"
        kubeconfig: myKubeconfig
        namespace: installPrometheusStack.installNamespace
    }

    initIngressNginxDashboard: grafana.#CreateIngressDashboard & {
        url: grafanaDomain
        username: "admin"
        password: installPrometheusStack.grafanaSecret.get
        waitGrafana: installPrometheusStack.kubePrometheus
    }

    initLokiDataSource: grafana.#CreateLokiDataSource & {
        url: grafanaDomain
        username: "admin"
        password: installPrometheusStack.grafanaSecret.get
        waitGrafana: installPrometheusStack.kubePrometheus
        waitLoki: installLokiStack.lokiStack
    }

    grafanaIngressToTargetCluster: {
        ingress: ingressNginx.#Ingress & {
            name: uri.out + "-grafana"
            className: "nginx"
            hostName: grafanaDomain
            path: "/"
            namespace: installPrometheusStack.installNamespace
            backendServiceName: installPrometheusStack.releaseName + "-grafana"
            ingressVersion: getIngressVersion.get
        }

        deploy: kubernetes.#Resources & {
            kubeconfig: myKubeconfig
            manifest: ingress.manifestStream
            namespace: installPrometheusStack.installNamespace
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
    }

    prometheusIngressToTargetCluster: {
        ingress: ingressNginx.#Ingress & {
            name: uri.out + "-prometheus"
            className: "nginx"
            hostName: prometheusDomain
            path: "/"
            namespace: installPrometheusStack.installNamespace
            backendServiceName: "prometheus-operated"
            backendServicePort: 9090
            ingressVersion: getIngressVersion.get
        }

        deploy: kubernetes.#Resources & {
            kubeconfig: myKubeconfig
            manifest: ingress.manifestStream
            namespace: installPrometheusStack.installNamespace
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
            namespace: installPrometheusStack.installNamespace
            backendServiceName: "alertmanager-operated"
            backendServicePort: 9093
            ingressVersion: getIngressVersion.get
        }

        deploy: kubernetes.#Resources & {
            kubeconfig: myKubeconfig
            manifest: ingress.manifestStream
            namespace: installPrometheusStack.installNamespace
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

installLokiStack: {
    installNamespace: "logging"

    lokiStack: helm.#Chart & {
        name: "loki"
        repository: "https://grafana.github.io/helm-charts"
        chart: "loki-stack"
        action: "installOrUpgrade"
        namespace: installLokiStack.installNamespace
        kubeconfig: myKubeconfig
        wait: true
        waitFor: {
            "/wait": from: installIngress.install
        }
    }

    // initNodeExporterDashboard: grafana.#CreateNodeExporterDashboard & {
    //     url: grafanaDomain
    //     username: "admin"
    //     password: installLokiStack.grafanaIngressToTargetCluster.grafanaSecret.get
    //     waitGrafana: lokiStack
    // }
}