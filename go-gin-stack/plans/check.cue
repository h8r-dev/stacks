package main

import(
  "github.com/h8r-dev/go-gin-stack/plans/check"
  "github.com/h8r-dev/cuelib/git/github"
  "alpha.dagger.io/dagger"
)

check_infra: check.#CheckInfra & {
    sourceCodeDir: sourceCodeDir
}

orgMember: github.#GetOrgMem & {
  organization: dagger.#Input & {string}
  accessToken: dagger.#Input & {dagger.#Secret}
}

createNocalhostTeam: github.#CreateNocalhostTeam & {
    source: orgMember
}