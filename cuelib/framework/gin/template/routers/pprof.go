package routers

import (
	"net/http/pprof"

	"github.com/gin-gonic/gin"
)

func initPProfRouter(r *gin.Engine) {
	group := r.Group("/debug/pprof")
	{
		group.GET("/", gin.WrapF(pprof.Index))
		group.GET("/cmdline", gin.WrapF(pprof.Cmdline))
		group.GET("/profile", gin.WrapF(pprof.Profile))
		group.POST("/symbol", gin.WrapF(pprof.Symbol))
		group.GET("/symbol", gin.WrapF(pprof.Symbol))
		group.GET("/trace", gin.WrapF(pprof.Trace))
		group.GET("/allocs", gin.WrapH(pprof.Handler("allocs")))
		group.GET("/block", gin.WrapH(pprof.Handler("block")))
		group.GET("/goroutine", gin.WrapH(pprof.Handler("goroutine")))
		group.GET("/heap", gin.WrapH(pprof.Handler("heap")))
		group.GET("/mutex", gin.WrapH(pprof.Handler("mutex")))
		group.GET("/threadcreate", gin.WrapH(pprof.Handler("threadcreate")))
	}
}
