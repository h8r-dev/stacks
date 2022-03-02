// package main

// import(
//     "alpha.dagger.io/kubernetes"
//     "alpha.dagger.io/kubernetes/helm"
//     "alpha.dagger.io/dagger"
//     "alpha.dagger.io/random"
//     "github.com/h8r-dev/go-gin-stack/plans/check"
// )

// myKubeconfig: dagger.#Input & {dagger.#Secret}

// suffix: random.#String & {
//     seed: ""
//     length: 6
// }

// // random domain
// domain: ".stack.h8r.io"

// // Nocalhost URL
// nocalhostDomain: suffix.out + ".nocalhost" + domain @dagger(output)

// // Grafana URL
// grafanaDomain: suffix.out + ".grafana" + domain @dagger(output)

// // Prometheus URL
// prometheusDomain: suffix.out + ".prom" + domain @dagger(output)

// // Alertmanager URL
// alertmanagerDomain: suffix.out + ".alert" + domain @dagger(output)

// installIngress: {
//     install: helm.#Chart & {
//         name: "ingress-nginx"
//         repository: "https://h8r-helm.pkg.coding.net/release/helm"
//         chart: "ingress-nginx"
//         namespace: "ingress-nginx"
//         action: "installOrUpgrade"
//         kubeconfig: myKubeconfig
//         wait: true
//     }

//     targetIngressEndpoint: check.#GetIngressEndpoint & {
//         kubeconfig: myKubeconfig
//     }
// }

// installNocalhost: {
//     installNamespace: "nocalhost"

//     nocalhost: helm.#Chart & {
//         name: "nocalhost"
//         repository: "https://nocalhost-helm.pkg.coding.net/nocalhost/nocalhost"
//         chart: "nocalhost"
//         namespace: installNamespace
//         action: "installOrUpgrade"
//         kubeconfig: myKubeconfig
//         wait: true
//     }

//     nocalhostIngress: check.#Ingress & {
//         name: suffix.out + "-nocalhost"
//         className: "nginx"
//         hostName: nocalhostDomain
//         path: "/"
//         namespace: installNamespace
//         backendServiceName: "nocalhost-web"
//     }

//     deploy: kubernetes.#Resources & {
//         kubeconfig: myKubeconfig
//         manifest: nocalhostIngress.manifestStream
//         namespace: installNamespace
//     }

//     createH8rIngress: {
//         create: check.#CreateH8rIngress & {
//             name: suffix.out + "-nocalhost"
//             host: installIngress.targetIngressEndpoint.get
//             domain: nocalhostDomain
//             port: "80"
//         }
//     }
// }



// installLokiStack: {
//     installNamespace: "loki"

//     lokiStack: helm.#Chart & {
//         name: "loki"
//         repository: "https://h8r-helm.pkg.coding.net/release/helm"
//         chart: "loki-stack"
//         action: "installOrUpgrade"
//         namespace: "loki"
//         kubeconfig: myKubeconfig
//         wait: true
//     }

//     grafanaIngressToTargetCluster: {
//         ingress: check.#Ingress & {
//             name: suffix.out + "-grafana"
//             className: "nginx"
//             hostName: grafanaDomain
//             path: "/"
//             namespace: installNamespace
//             backendServiceName: "loki-grafana"
//         }

//         deploy: kubernetes.#Resources & {
//             kubeconfig: myKubeconfig
//             manifest: ingress.manifestStream
//             namespace: installNamespace
//         }

//         createH8rIngress: {
//             create: check.#CreateH8rIngress & {
//                 name: suffix.out + "-grafana"
//                 host: installIngress.targetIngressEndpoint.get
//                 domain: grafanaDomain
//                 port: "80"
//             }
//         }

//         // Grafana secret, username admin
//         grafanaSecret: check.#GetLokiSecret & {
//             kubeconfig: myKubeconfig
//         }
//     }

//     prometheusIngressToTargetCluster: {
//         ingress: check.#Ingress & {
//             name: suffix.out + "-prometheus"
//             className: "nginx"
//             hostName: prometheusDomain
//             path: "/"
//             namespace: installNamespace
//             backendServiceName: "loki-prometheus-server"
//         }

//         deploy: kubernetes.#Resources & {
//             kubeconfig: myKubeconfig
//             manifest: ingress.manifestStream
//             namespace: installNamespace
//         }

//         createH8rIngress: {
//             create: check.#CreateH8rIngress & {
//                 name: suffix.out + "-prometheus"
//                 host: installIngress.targetIngressEndpoint.get
//                 domain: prometheusDomain
//                 port: "80"
//             }
//         }
//     }

//     alertmanagerIngressToTargetCluster: {
//         ingress: check.#Ingress & {
//             name: suffix.out + "-alertmanager"
//             className: "nginx"
//             hostName: alertmanagerDomain
//             path: "/"
//             namespace: installNamespace
//             backendServiceName: "loki-prometheus-alertmanager"
//         }

//         deploy: kubernetes.#Resources & {
//             kubeconfig: myKubeconfig
//             manifest: ingress.manifestStream
//             namespace: installNamespace
//         }

//         createH8rIngress: {
//             create: check.#CreateH8rIngress & {
//                 name: suffix.out + "-alertmanager"
//                 host: installIngress.targetIngressEndpoint.get
//                 domain: alertmanagerDomain
//                 port: "80"
//             }
//         }
//     }
// }