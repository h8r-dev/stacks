package routers

import (
	"github.com/gin-gonic/gin"
	swaggerFiles "github.com/swaggo/files"
	ginSwagger "github.com/swaggo/gin-swagger"

	"gin-sample/server"
	"gin-sample/service"
)

func initCommonRouter(r *gin.Engine) {
	r.GET("/api/swagger/*any", ginSwagger.WrapHandler(swaggerFiles.Handler))
	commonSvc := service.NewCommonService()
	server.NewGinHttpServer(r, commonSvc)
}
