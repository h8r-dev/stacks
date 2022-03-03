package main

import(
  "github.com/h8r-dev/cuelib/deploy/helm"
  "github.com/h8r-dev/cuelib/infra/h8r"
)

// App domain
appDomain: suffix.out + ".go-gin.h8r.app" @dagger(output)

// Application install namespace
appInstallNamespace: "production"

helmDeploy: helm.#Deploy & {
  helmPath: "helm"
  releaseName: initRepo.applicationName
  repoUrl: initHelmRepo.gitUrl
  ghcrName: initRepo.organization
  ghcrPassword: initRepo.accessToken
  // TODO set as default dir
  sourceCodeDir: initRepo.sourceCodeDir
  namespace: appInstallNamespace
  ingressHostName: appDomain
}

createH8rIngress: {
  create: h8r.#CreateH8rIngress & {
      name: suffix.out + "-go-gin"
      host: installIngress.targetIngressEndpoint.get
      domain: appDomain
      port: "80"
  }
}
