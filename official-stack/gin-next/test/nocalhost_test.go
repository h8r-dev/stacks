package gin_next_stack_test

import (
	"fmt"
	"net/http"

	"github.com/gavv/httpexpect/v2"

	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
)

type Login struct {
	Email    string `form:"email"`
	Password string `form:"password"`
}

var _ = Describe("Nocalhost", func() {
	var (
		url   string
		login Login
	)

	// TODO: get url and password form hln cli, when hln supports output json `hln status <app> -o json`
	BeforeEach(func() {
		url = "http://nocalhost.h8r.site"
		login = Login{
			Email:    "admin@admin.com",
			Password: "123456",
		}
	})

	It("check nocalhost", func() {
		e := httpexpect.WithConfig(httpexpect.Config{
			BaseURL: url,
			Client: &http.Client{
				Jar: httpexpect.NewJar(),
			},
			Reporter: httpexpect.NewAssertReporter(GinkgoT()),
			Printers: []httpexpect.Printer{
				httpexpect.NewCompactPrinter(GinkgoT()),
			},
		})

		// login, get token
		token := e.POST("/v1/login").WithForm(login).
			Expect().
			Status(http.StatusOK).
			JSON().Object().
			ValueEqual("code", 0).
			Value("data").Object().
			Value("token").String().Raw()

		// check cluster
		e.GET("/v1/cluster").WithHeader("Authorization", fmt.Sprintf("Bearer %s", token)).
			Expect().
			Status(http.StatusOK).
			JSON().Object().
			ContainsKey("code").ValueEqual("code", 0).
			Value("data").Array().First().Object().
			ValueEqual("name", "initCluster")

		// check dev spaces
		cluster := e.GET("/v2/dev_space").WithHeader("Authorization", fmt.Sprintf("Bearer %s", token)).
			Expect().
			Status(http.StatusOK).
			JSON().Object().
			ContainsKey("code").ValueEqual("code", 0).
			Value("data").Array().Iter()

		Expect(len(cluster) > 0).Should(BeTrue())
	})
})
