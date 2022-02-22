package main

import(
  "github.com/h8r-dev/go-gin-stack/plans/check"
)

check_infra: check.#CheckInfra & {
    sourceCodeDir: sourceCodeDir
}