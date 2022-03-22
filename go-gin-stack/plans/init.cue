package main

import (
	"github.com/h8r-dev/cuelib/git/github"
	"github.com/h8r-dev/cuelib/infra/nocalhost"
)

initRepo: github.#InitRepo & {
	checkInfra:     check_infra.check
	sourceCodePath: "code/go-gin"
	suffix:         ""
}

initFrontendRepo: github.#InitRepo & {
	applicationName: initRepo.applicationName
	suffix:          "-front"
	accessToken:     initRepo.accessToken
	organization:    initRepo.organization
	checkInfra:      check_infra.check
	sourceCodePath:  "code/vue-front"
	sourceCodeDir:   initRepo.sourceCodeDir
}

// What's Next
initHelmRepo: github.#InitRepo & {
	applicationName: initRepo.applicationName
	suffix:          "-helm"
	accessToken:     initRepo.accessToken
	organization:    initRepo.organization
	checkInfra:      check_infra.check
	sourceCodePath:  "helm"
	sourceCodeDir:   initRepo.sourceCodeDir
	isHelmChart:     "true"
}

orgMember: github.#GetOrgMem & {
	accessToken:  initRepo.accessToken
	organization: initRepo.organization
}

initNocalhostData: {
	login: nocalhost.#LoginNocalhost & {
		waitNocalhost: installNocalhost.nocalhost
		nocalhostURL:  nocalhostDomain
	}

	createUser: nocalhost.#CreateNocalhostTeam & {
		waitNocalhost:        installNocalhost.nocalhost
		githubMemberSource:   orgMember
		nocalhostTokenSource: login
	}

	createCluster: nocalhost.#CreateNocalhostCluster & {
		waitNocalhost:        installNocalhost.nocalhost
		nocalhostTokenSource: login
		"myKubeconfig":       myKubeconfig
	}

	createApplication: nocalhost.#CreateNocalhostApplication & {
		waitNocalhost:        installNocalhost.nocalhost
		nocalhostTokenSource: login
		applicationName:      initRepo.applicationName
		gitUrl:               initHelmRepo.gitUrl
	}

	createDevSpace: nocalhost.#CreateNocalhostDevSpace & {
		waitNocalhost:        installNocalhost.nocalhost
		nocalhostTokenSource: login
		waitUser:             createUser
		waitCluster:          createCluster
	}
}
