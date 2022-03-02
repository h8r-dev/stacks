//package main

//import(
    //"alpha.dagger.io/kubernetes"
    //"alpha.dagger.io/kubernetes/helm"
    //"alpha.dagger.io/dagger"
    //"github.com/h8r-dev/go-gin-stack/plans/check"
//)

//myKubeconfig: dagger.#Input & {dagger.#Secret}

// installIngress: helm.#Chart & {
//     name: "ingress-nginx"
//     repository: "https://kubernetes.github.io/ingress-nginx"
//     chart: "ingress-nginx"
//     namespace: "ingress-nginx"
//     action: "installOrUpgrade"
//     kubeconfig: myKubeconfig
// }

// installNocalhost: helm.#Chart & {
//     name: "nocalhost"
//     repository: "https://nocalhost-helm.pkg.coding.net/nocalhost/nocalhost"
//     chart: "nocalhost"
//     namespace: "nocalhost"
//     action: "installOrUpgrade"
//     kubeconfig: myKubeconfig
// }

// nocalhostIngress: {
//     ingress: check.#Ingress & {
//         name: "nocalhost-ingress"
//         className: "ingress-nginx"
//         hostName: "coding.io"
//         path: "/nocalhost"
//         namespace: "nocalhost"
//         backendServiceName: "nocalhost-web"
//     }

// 	deploy: kubernetes.#Resources & {
// 		"kubeconfig": myKubeconfig
// 		manifest: ingress.manifestStream
// 	}
// }