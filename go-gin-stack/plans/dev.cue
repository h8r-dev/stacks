package h8r

import(
  "github.com/h8r-dev/stack-hub/h8r/tencent"
)

h8r: tencent.#H8r & {
  helmPath: "helm"
  releaseName: "stack-hub"
  repoUrl: "git@github.com:h8r-dev/stack-hub.git"
}