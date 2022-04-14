package main

import (
	"fmt"
	"log"
	"net/http"

	"github.com/gin-gonic/gin"

	"go-gin/models"
	"go-gin/pkg/gredis"
	"go-gin/pkg/setting"
	"go-gin/pkg/util"
	"go-gin/routers"
)

func init() {
	setting.Setup()
	models.Setup()
	gredis.Setup()
	util.Setup()
}

// @title Golang Gin API
// @version 1.0
// @description An example of gin
// @termsOfService https://h8r.io
// @license.name MIT
// @license.url https://go-gin/blob/master/LICENSE
func main() {
	gin.SetMode(setting.ServerSetting.RunMode)

	routersInit := routers.InitRouter()
	readTimeout := setting.ServerSetting.ReadTimeout
	writeTimeout := setting.ServerSetting.WriteTimeout
	endPoint := fmt.Sprintf(":%d", setting.ServerSetting.HttpPort)
	maxHeaderBytes := 1 << 20

	server := &http.Server{
		Addr:           endPoint,
		Handler:        routersInit,
		ReadTimeout:    readTimeout,
		WriteTimeout:   writeTimeout,
		MaxHeaderBytes: maxHeaderBytes,
	}

	log.Printf("[info] start http server listening %s", endPoint)

	server.ListenAndServe()
}
