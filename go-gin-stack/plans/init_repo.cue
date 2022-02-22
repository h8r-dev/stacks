package main

import(
    "github.com/h8r-dev/cuelib/git/github"
)

initRepo: github.#InitRepo & {
    checkInfra: check_infra.check
    sourceCodePath: "code/go-gin"
}

initFrontendRepo: github.#InitRepo & {
    applicationName: initRepo.applicationName + "-front"
    accessToken: initRepo.accessToken
    organization: initRepo.organization
    checkInfra: check_infra.check
    sourceCodePath: "code/vue-front"
    sourceCodeDir: initRepo.sourceCodeDir
}

initHelmRepo: github.#InitRepo & {
    applicationName: initRepo.applicationName
    accessToken: initRepo.accessToken
    organization: initRepo.organization
    checkInfra: check_infra.check
    sourceCodePath: "helm"
    sourceCodeDir: initRepo.sourceCodeDir
    isHelmChart: "true"
}