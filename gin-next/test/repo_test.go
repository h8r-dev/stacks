package gin_next_stack_test

import (
	"context"
	"os"
	"strings"

	"github.com/google/go-github/v43/github"
	"golang.org/x/oauth2"

	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
)

var _ = Describe("Repos", func() {
	BeforeEach(func() {
	})

	It("should create backend, frontend, deploy repos", func() {

		githubOrg := os.Getenv("ORGANIZATION")
		appName := os.Getenv("APP_NAME")
		githubToken := os.Getenv("GITHUB_TOKEN")

		ctx := context.Background()
		ts := oauth2.StaticTokenSource(
			&oauth2.Token{AccessToken: githubToken},
		)
		tc := oauth2.NewClient(ctx, ts)

		client := github.NewClient(tc)
		user, _, err := client.Users.Get(ctx, "")

		Expect(err).To(BeNil())

		userName := *user.Login

		var repos []*github.Repository

		// list all repositories
		if userName == githubOrg {
			// list all repositories for the authenticated user
			opt := &github.RepositoryListOptions{Type: "all", Sort: "created"}
			repos, _, err = client.Repositories.List(ctx, "", opt)
		} else {
			// list public repositories for given org
			opt := &github.RepositoryListByOrgOptions{Type: "all", Sort: "created"}
			repos, _, err = client.Repositories.ListByOrg(ctx, githubOrg, opt)
		}

		Expect(err).To(BeNil())

		// find repo with app name prefix
		foundBackend := false
		foundFrontend := false
		foundDeploy := false
		for _, repo := range repos {
			rn := *repo.Name
			if !strings.HasPrefix(rn, appName) {
				continue
			}
			switch rn {
			case appName + "-backend":
				foundBackend = true
			case appName + "-frontend":
				foundFrontend = true
			case appName + "-deploy":
				foundDeploy = true
			}
		}

		Expect(foundBackend).To(BeTrue())
		Expect(foundFrontend).To(BeTrue())
		Expect(foundDeploy).To(BeTrue())
	})
})
