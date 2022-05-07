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

	r.Use(gin.Logger())
	r.Use(gin.Recovery())

	p := newPromGauges(r)

	r.GET("/inc", func(c *gin.Context) {
		p.IncrementGaugeValue("counter", []string{"demo"})
		p.IncrementGaugeValue("gauge", []string{"demo"})
		c.String(http.StatusOK, "Gauge incremented")
	})
	r.GET("/dec", func(c *gin.Context) {
		p.IncrementGaugeValue("counter", []string{"demo"})
		p.DecrementGaugeValue("gauge", []string{"demo"})
		c.String(http.StatusOK, "Gauge decremented")
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

func newPromGauges(r *gin.Engine) *ginprom.Prometheus {
	p := ginprom.New(
		ginprom.Engine(r),
		ginprom.Subsystem("http"),
		ginprom.Path("/metrics"),
	)
	p.AddCustomGauge(
		"gauge",
		"Gauge both increments and decrements",
		[]string{"part"})
	p.SetGaugeValue("gauge", []string{"demo"}, 0)
	p.AddCustomGauge(
		"counter",
		"Counter increments only",
		[]string{"part"})
	p.SetGaugeValue("counter", []string{"demo"}, 0)
	r.Use(p.Instrument())
	return p
}
