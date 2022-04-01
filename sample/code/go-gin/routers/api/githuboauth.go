package api

import (
	"fmt"

	"github.com/gin-gonic/gin"
)

func GithubRedirect(c *gin.Context) {
	code := c.Query("code")
	fmt.Println(code)
}
