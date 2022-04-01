package nocalhost

import (
	"strings"
	"dagger.io/dagger"
	"github.com/h8r-dev/gin-vue/plans/cuelib/github"
)

#InitData: {
	url:                string
	githubAccessToken:  dagger.#Secret
	githubOrganization: string
	kubeconfig:         string | dagger.#Secret
	appName:            string
	appGitURL:          string
	waitFor:            bool

	getToken: #GetToken & {
		"url":     url
		"waitFor": waitFor
	}

	githubOrganizationMembers: github.#GetOrganizationMembers & {
		accessToken:  githubAccessToken
		organization: githubOrganization
	}

	createTeam: #CreateTeam & {
		token:   getToken.output
		members: githubOrganizationMembers.output
		"url":   url
	}

	createCluster: #CreateCluster & {
		token:        getToken.output
		"url":        url
		"kubeconfig": kubeconfig
	}

	createApplication: #CreateApplication & {
		token:       getToken.output
		"url":       url
		"appName":   appName
		"appGitURL": strings.Replace(appGitURL, "\n", "", -1)
	}

	createDevSpace: #CreateDevSpace & {
		token:   getToken.output
		"url":   url
		waitFor: createTeam.success & createCluster.success
	}
}
