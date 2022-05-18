package sample_stack_test

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
    print("Sample stack test suite running...")
	})

	It("should create remix, deploy repos", func() {
		appName := os.Getenv("APP_NAME")
		githubToken := os.Getenv("GITHUB_TOKEN")

		ctx := context.Background()
		ts := oauth2.StaticTokenSource(
			&oauth2.Token{AccessToken: githubToken},
		)
		tc := oauth2.NewClient(ctx, ts)

		client := github.NewClient(tc)

		var repos []*github.Repository

    // list all repositories for the authenticated user
    opt := &github.RepositoryListOptions{Type: "all", Sort: "created"}
    repos, _, err := client.Repositories.List(ctx, "", opt)

		Expect(err).To(BeNil())

		// find repo with app name prefix
		foundRemixRepo := false
		foundDeploy := false

		for _, repo := range repos {
			rn := *repo.Name
			if !strings.HasPrefix(rn, appName) {
				continue
			}
			switch rn {
      case appName:
        foundRemixRepo = true
      case appName + "-deploy":
        foundDeploy = true
			}
		}

		Expect(foundRemixRepo).To(BeTrue())
		Expect(foundDeploy).To(BeTrue())
	})
})
