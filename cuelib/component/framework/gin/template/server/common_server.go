package server

import (
	"net/http"

	"github.com/gin-gonic/gin"

	"gin-sample/domain"
)

type commonServer struct {
	commonService domain.CommonService
}

// GetNameHandler returns the name of the server
// @Tags         common
// @Summary 	  Returns the name of the server
// @Produce json
// @Success 200 {object} string "The name of the server"
// @Failure 400 {object} domain.ErrResponse
// @Failure 500 {object} domain.ErrResponse
// @Router /name [get]
func (c *commonServer) GetNameHandler(context *gin.Context) {
	context.JSON(200, gin.H{
		"name": c.commonService.GetName(),
	})
}

// HealthHandler check
// @Tags         common
// @Summary 	 Health check
// @Produce json
// @Success 200 {object} string "OK"
// @Failure 400 {object} domain.ErrResponse
// @Failure 500 {object} domain.ErrResponse
// @Router /health [get]
func (c *commonServer) HealthHandler(context *gin.Context) {
	context.String(http.StatusOK, "OK")
}

func NewGinHttpServer(r *gin.Engine, commonService domain.CommonService) {
	commonServer := &commonServer{
		commonService: commonService,
	}
	r.GET("/name", commonServer.GetNameHandler)
	r.GET("/health", commonServer.HealthHandler)
}
