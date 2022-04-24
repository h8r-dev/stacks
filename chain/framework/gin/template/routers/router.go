package routers

import (
	"net/http"

	"github.com/gin-gonic/gin"

	_ "go-gin/docs"

	swaggerFiles "github.com/swaggo/files"
	ginSwagger "github.com/swaggo/gin-swagger"

	"go-gin/middleware/jwt"

	"github.com/Depado/ginprom"
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

	r.GET("/ping", func(c *gin.Context) {
		c.String(http.StatusOK, "OK")
	})

	r.GET("/", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"message": "heighlienr gin framework"})
	})

	//r.POST("/auth", api.GetAuth)
	r.GET("/api/swagger/*any", ginSwagger.WrapHandler(swaggerFiles.Handler))

	apiv1 := r.Group("/api/v1")
	apiv1.Use(jwt.JWT())
	{
		apiv1.GET("/hello", func(c *gin.Context) {
			c.String(http.StatusOK, "Request from frontend")
		})
	}

	return r
}
