package jwt

import (
	"github.com/golang-jwt/jwt/v4"
	e2 "go-gin/internal/e"
	"net/http"

	"github.com/gin-gonic/gin"

	"go-gin/pkg/util"
)

// JWT is jwt middleware
func JWT() gin.HandlerFunc {
	return func(c *gin.Context) {
		var code int
		var data interface{}

		code = e2.SUCCESS
		token := c.Query("token")
		if token == "" {
			code = e2.INVALID_PARAMS
		} else {
			_, err := util.ParseToken(token)
			if err != nil {
				switch err.(*jwt.ValidationError).Errors {
				case jwt.ValidationErrorExpired:
					code = e2.INVALID_PARAMS
				default:
					code = e2.INVALID_PARAMS
				}
			}
		}

		if code != e2.SUCCESS {
			c.JSON(http.StatusUnauthorized, gin.H{
				"code": code,
				"msg":  e2.GetMsg(code),
				"data": data,
			})

			c.Abort()
			return
		}

		c.Next()
	}
}
