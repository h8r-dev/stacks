package gin_vue_stack_test

import (
	"context"
	"os"
	"strings"

	"github.com/google/go-github/github"

	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
)

var _ = Describe("Repos", func() {
	BeforeEach(func() {
	})

	It("should create backend, frontend, deploy repos", func() {
		client := github.NewClient(nil)

		githubOrg := os.Getenv("ORGANIZATION")
		appName := os.Getenv("APP_NAME")

		// list public repositories for given org
		opt := &github.RepositoryListByOrgOptions{Type: "public"}
		repos, _, err := client.Repositories.ListByOrg(context.Background(), githubOrg, opt)
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
			case appName + "backend":
				foundBackend = true
			case appName + "frontend":
				foundFrontend = true
			case appName + "deploy":
				foundDeploy = true
			}
		}

		Expect(foundBackend).To(BeTrue())
		Expect(foundFrontend).To(BeTrue())
		Expect(foundDeploy).To(BeTrue())
	})
})
