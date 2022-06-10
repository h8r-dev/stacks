package routers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	swaggerFiles "github.com/swaggo/files"
	ginSwagger "github.com/swaggo/gin-swagger"

	"gin-sample/server"
	"gin-sample/service"
)

func initCommonRouter(r *gin.Engine) {
	r.GET("/", HelloHeighliner)
	r.GET("/api/swagger/*any", ginSwagger.WrapHandler(swaggerFiles.Handler))
	commonSvc := service.NewCommonService()
	server.NewGinHttpServer(r, commonSvc)
}

func HelloHeighliner(context *gin.Context) {
	context.String(http.StatusOK, "Hello Heighliner!")
}
