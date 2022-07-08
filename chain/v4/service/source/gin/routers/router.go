package routers

import (
	"github.com/gin-gonic/gin"

	_ "gin-sample/docs"
)

// InitRouter initialize routing information
func InitRouter(r *gin.Engine) {
	initCommonRouter(r)
	initPProfRouter(r)
}
