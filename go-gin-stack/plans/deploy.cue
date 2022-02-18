package main

import(
  "github.com/h8r-dev/plans/h8r"
)

deploy: h8r.#Deploy & {
  helmPath: "helm"
  releaseName: initRepo.applicationName
  repoUrl: initHelmRepo.gitUrl
  ghcrName: initRepo.organization
  ghcrPassword: initRepo.accessToken
  // TODO set as default dir
  kubeconfigPath: "infra/kubeconfig/config.yaml"
  sourceCodeDir: initRepo.sourceCodeDir
}