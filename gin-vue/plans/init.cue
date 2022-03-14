package main

import (
	"dagger.io/dagger"

	"github.com/h8r-dev/cuelib/git/github"
	"github.com/h8r-dev/cuelib/infra/nocalhost"
)

dagger.#Plan & {
	// FIXME: Ideally we would want to automatically set the platform's arch identical to the host
	// to avoid the performance hit caused by qemu (linter goes from <3s to >3m when arch is x86)
	// Uncomment if running locally on Mac M1 to bypass qemu
	platform: "linux/aarch64"
	// platform: "linux/amd64"

	client: filesystem: "code/go-gin": read: exclude: [
		"README.md",
	]

	actions: {
		create: {
			initBackendRepo: {

			}
			initFrontendRepo: {

			}
			initHelmRepo: {
			}
		}
		delete: {
		}
	}
}

initRepo: github.#InitRepo & {
	checkInfra:     check_infra.check
	sourceCodePath: "code/go-gin"
}

initFrontendRepo: github.#InitRepo & {
	applicationName: initRepo.applicationName + "-front"
	accessToken:     initRepo.accessToken
	organization:    initRepo.organization
	checkInfra:      check_infra.check
	sourceCodePath:  "code/vue-front"
	sourceCodeDir:   initRepo.sourceCodeDir
}

// What's Next
initHelmRepo: github.#InitRepo & {
	applicationName: initRepo.applicationName
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
		myKubeconfig:         helmDeploy.myKubeconfig
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
