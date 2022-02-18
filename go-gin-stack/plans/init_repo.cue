package main

import(
    "github.com/h8r-dev/plans/h8r"
    // "alpha.dagger.io/io"
)

// sourceCodeDir: io.#Dir & {
//     read: tree: "."
// }

initRepo: h8r.#InitRepo & {
    checkInfra: check_infra.check
    sourceCodePath: "code/go-gin"
}

initFrontendRepo: h8r.#InitRepo & {
    applicationName: initRepo.applicationName + "-front"
    accessToken: initRepo.accessToken
    organization: initRepo.organization
    checkInfra: check_infra.check
    sourceCodePath: "code/vue-front"
    sourceCodeDir: initRepo.sourceCodeDir
}

initHelmRepo: h8r.#InitRepo & {
    applicationName: initRepo.applicationName
    accessToken: initRepo.accessToken
    organization: initRepo.organization
    checkInfra: check_infra.check
    sourceCodePath: "helm"
    sourceCodeDir: initRepo.sourceCodeDir
    isHelmChart: "true"
}