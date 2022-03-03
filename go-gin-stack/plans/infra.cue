package main

import(
    "alpha.dagger.io/kubernetes"
    "github.com/h8r-dev/cuelib/deploy/helm"
    "alpha.dagger.io/random"
    ingressNginx "github.com/h8r-dev/cuelib/infra/ingress"
    "github.com/h8r-dev/cuelib/infra/h8r"
    //"github.com/h8r-dev/cuelib/infra/loki"
)

suffix: random.#String & {
    seed: ""
    length: 6
}

// Infra domain
infraDomain: ".stack.h8r.io"

// Nocalhost URL
nocalhostDomain: suffix.out + ".nocalhost" + infraDomain @dagger(output)

// Grafana URL
grafanaDomain: suffix.out + ".grafana" + infraDomain @dagger(output)

// Prometheus URL
prometheusDomain: suffix.out + ".prom" + infraDomain @dagger(output)

// Alertmanager URL
alertmanagerDomain: suffix.out + ".alert" + infraDomain @dagger(output)

installIngress: {
    install: helm.#Chart & {
        name: "ingress-nginx"
        repository: "https://h8r-helm.pkg.coding.net/release/helm"
        chart: "ingress-nginx"
        namespace: "ingress-nginx"
        action: "installOrUpgrade"
        kubeconfig: helmDeploy.myKubeconfig
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
    }

    nocalhostIngress: ingressNginx.#Ingress & {
        name: suffix.out + "-nocalhost"
        className: "nginx"
        hostName: nocalhostDomain
        path: "/"
        namespace: installNamespace
        backendServiceName: "nocalhost-web"
    }

    deploy: kubernetes.#Resources & {
        kubeconfig: helmDeploy.myKubeconfig
        manifest: nocalhostIngress.manifestStream
        namespace: installNamespace
    }

    createH8rIngress: {
        create: h8r.#CreateH8rIngress & {
            name: suffix.out + "-nocalhost"
            host: installIngress.targetIngressEndpoint.get
            domain: nocalhostDomain
            port: "80"
        }
    }
}



// installLokiStack: {
//     installNamespace: "loki"

//     lokiStack: helm.#Chart & {
//         name: "loki"
//         repository: "https://h8r-helm.pkg.coding.net/release/helm"
//         chart: "loki-stack"
//         action: "installOrUpgrade"
//         namespace: "loki"
//         kubeconfig: helmDeploy.myKubeconfig
//         wait: true
//     }

//     grafanaIngressToTargetCluster: {
//         ingress: ingressNginx.#Ingress & {
//             name: suffix.out + "-grafana"
//             className: "nginx"
//             hostName: grafanaDomain
//             path: "/"
//             namespace: installNamespace
//             backendServiceName: "loki-grafana"
//         }

//         deploy: kubernetes.#Resources & {
//             kubeconfig: helmDeploy.myKubeconfig
//             manifest: ingress.manifestStream
//             namespace: installNamespace
//         }

//         createH8rIngress: {
//             create: h8r.#CreateH8rIngress & {
//                 name: suffix.out + "-grafana"
//                 host: installIngress.targetIngressEndpoint.get
//                 domain: grafanaDomain
//                 port: "80"
//             }
//         }

//         // Grafana secret, username admin
//         grafanaSecret: loki.#GetLokiSecret & {
//             kubeconfig: helmDeploy.myKubeconfig
//         }
//     }

//     prometheusIngressToTargetCluster: {
//         ingress: ingressNginx.#Ingress & {
//             name: suffix.out + "-prometheus"
//             className: "nginx"
//             hostName: prometheusDomain
//             path: "/"
//             namespace: installNamespace
//             backendServiceName: "loki-prometheus-server"
//         }

//         deploy: kubernetes.#Resources & {
//             kubeconfig: helmDeploy.myKubeconfig
//             manifest: ingress.manifestStream
//             namespace: installNamespace
//         }

//         createH8rIngress: {
//             create: h8r.#CreateH8rIngress & {
//                 name: suffix.out + "-prometheus"
//                 host: installIngress.targetIngressEndpoint.get
//                 domain: prometheusDomain
//                 port: "80"
//             }
//         }
//     }

//     alertmanagerIngressToTargetCluster: {
//         ingress: ingressNginx.#Ingress & {
//             name: suffix.out + "-alertmanager"
//             className: "nginx"
//             hostName: alertmanagerDomain
//             path: "/"
//             namespace: installNamespace
//             backendServiceName: "loki-prometheus-alertmanager"
//         }

//         deploy: kubernetes.#Resources & {
//             kubeconfig: helmDeploy.myKubeconfig
//             manifest: ingress.manifestStream
//             namespace: installNamespace
//         }

//         createH8rIngress: {
//             create: h8r.#CreateH8rIngress & {
//                 name: suffix.out + "-alertmanager"
//                 host: installIngress.targetIngressEndpoint.get
//                 domain: alertmanagerDomain
//                 port: "80"
//             }
//         }
//     }
// }