package main

import(
  "github.com/h8r-dev/plans/h8r"
)

check_infra: h8r.#CheckInfra & {
    sourceCodeDir: initRepo.sourceCodeDir
}