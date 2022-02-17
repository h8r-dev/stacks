package main

import(
    "alpha.dagger.io/dagger"
    "github.com/h8r-dev/plans/h8r"
)

initRepo: h8r.#InitRepo & {
  applicationName: dagger.#Input
  organization: dagger.#Input
}
