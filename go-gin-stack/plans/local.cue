// package h8r

// import(
//   "alpha.dagger.io/dagger"
//   "alpha.dagger.io/git"
//   "alpha.dagger.io/tencent"
// )

// createRepo: git.#Create & {
//   repoName: dagger.#Input
// }

// cluster: tencent.#Tke & {
//   secretId: dagger.#Input
//   secretKey: dagger.#Secret
// }

// helm: tencent.#Helm & {
//   releaseName: createRepo.repoName
//   helmPath: "helm"
//   repoUrl: createRepo.create
//   kubeconfig: cluster.references
//   namespace: "h8r"
// }