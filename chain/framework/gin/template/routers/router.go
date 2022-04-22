package routers

import (
	"github.com/gin-gonic/gin"
	"net/http"

	swaggerFiles "github.com/swaggo/files"
	"github.com/swaggo/gin-swagger"
	_ "go-gin/docs"

	"github.com/Depado/ginprom"
	"go-gin/middleware/jwt"
	"go-gin/routers/api"
	"go.opentelemetry.io/contrib/instrumentation/github.com/gin-gonic/gin/otelgin"
)

// InitRouter initialize routing information
func InitRouter() *gin.Engine {
	r := gin.New()
	// TODO: change service name to real name
	r.Use(otelgin.Middleware("go-gin"))

	p := ginprom.New(
		ginprom.Engine(r),
		ginprom.Subsystem("gin"),
		ginprom.Path("/api/metrics"),
	)
	r.Use(p.Instrument())

	r.Use(gin.Logger())
	r.Use(gin.Recovery())

	r.GET("/health", func(c *gin.Context) {
		c.String(http.StatusOK, "OK")
	})
	r.POST("/auth", api.GetAuth)
	r.GET("/api/swagger/*any", ginSwagger.WrapHandler(swaggerFiles.Handler))

	apiv1 := r.Group("/api/v1")
	apiv1.Use(jwt.JWT())
	{

	}

	return r
}
