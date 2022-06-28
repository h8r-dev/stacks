package gin_vue_stack_test

import (
	"context"
	"os"

	"github.com/google/go-github/v45/github"
	"golang.org/x/oauth2"

	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
)

var _ = Describe("Repos", func() {
	var (
		githubOrg   string
		appName     string
		githubToken string
		repos       []string
	)

	BeforeEach(func() {
		githubOrg = os.Getenv("ORGANIZATION")
		Expect(githubOrg).ShouldNot(BeEmpty())

		appName = os.Getenv("APP_NAME")
		Expect(appName).ShouldNot(BeEmpty())

		githubToken = os.Getenv("GITHUB_TOKEN")
		Expect(githubToken).ShouldNot(BeEmpty())

		repos = []string{appName + "-backend", appName + "-frontend", appName + "-deploy"}

	})

	It("should create backend, frontend, deploy repos", func() {
		ctx := context.Background()
		ts := oauth2.StaticTokenSource(
			&oauth2.Token{AccessToken: githubToken},
		)
		tc := oauth2.NewClient(ctx, ts)

		client := github.NewClient(tc)

		for _, repo := range repos {
			_, _, err := client.Repositories.Get(ctx, githubOrg, repo)
			Expect(err).Should(BeNil())
		}
	})
})
