package main

import (
	"fmt"
	"log"
	"net/http"

	"github.com/gin-gonic/gin"

	"gin-sample/middleware"
	"gin-sample/routers"
	"gin-sample/setup"
	"gin-sample/vars"
)

// @title gin-sample API
// @version 1.0
// @description This is a gin-sample API
// @termsOfService https://h8r.io
// @license.name MIT
// @license.url https://go-gin/blob/master/LICENSE
func main() {
	if err := setup.Setup(); err != nil {
		log.Fatalf("setup.Setup() error: %v", err)
	}

	if err := setup.AutoMigrateDB(); err != nil {
		log.Fatalf("setup.AutoMigrateDB() error: %v", err)
	}

	gin.SetMode(vars.ServerSetting.RunMode)
	r := gin.Default()
	vars.Prometheus.Use(r)
	// init global middleware
	middleware.InitMiddleware(r)
	// init routers
	routers.InitRouter(r)

	endPoint := fmt.Sprintf(":%d", vars.ServerSetting.HttpPort)
	maxHeaderBytes := 1 << 20

	server := &http.Server{
		Addr:           endPoint,
		Handler:        r,
		ReadTimeout:    vars.ServerSetting.ReadTimeout,
		WriteTimeout:   vars.ServerSetting.WriteTimeout,
		MaxHeaderBytes: maxHeaderBytes,
	}

	log.Printf("start http server listening %s\n", endPoint)

	if err := server.ListenAndServe(); err != nil {
		log.Fatalf("ListenAndServe failed. error: %v", err)
	}
}
