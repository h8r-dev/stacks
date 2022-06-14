package middleware

import (
	"github.com/gin-gonic/gin"
	"go.opentelemetry.io/contrib/instrumentation/github.com/gin-gonic/gin/otelgin"

	"gin-sample/vars"
)

func InitMiddleware(r *gin.Engine) {
	// TODO: change service name to real name
	r.Use(otelgin.Middleware(vars.AppName))
}
