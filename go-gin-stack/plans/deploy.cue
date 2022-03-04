package main

import(
  "github.com/h8r-dev/cuelib/deploy/helm"
  "github.com/h8r-dev/cuelib/infra/h8r"
)

// Application install namespace
appInstallNamespace: "production"

// App domain prefix
appDomain: suffix.out + ".go-gin.h8r.app"

// App domain
showAppDomain: appInstallNamespace + "." + appDomain @dagger(output)

// Dev domain
devDomain: ".dev.go-gin.h8r.app"

helmDeploy: helm.#Deploy & {
  helmPath: "helm"
  releaseName: initRepo.applicationName
  repoUrl: initHelmRepo.gitUrl
  ghcrName: initRepo.organization
  ghcrPassword: initRepo.accessToken
  // TODO set as default dir
  sourceCodeDir: initRepo.sourceCodeDir
  namespace: appInstallNamespace
  // helm chart has namespace host prefix
  ingressHostName: appDomain
}

createH8rIngress: {
  app: h8r.#CreateH8rIngress & {
    name: suffix.out + "-go-gin"
    host: installIngress.targetIngressEndpoint.get
    domain: appInstallNamespace + "." + appDomain
    port: "80"
  }

  dev: h8r.#CreateH8rIngressBatch & {
    name: "dev"
    host: installIngress.targetIngressEndpoint.get
    domain: devDomain
    port: "80"
    batchJson: initNocalhostData.createDevSpace
  }
}