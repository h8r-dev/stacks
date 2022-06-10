# Gin-sample

## Features
- Gin
- GORM
- Zap
- Prometheus
- Viper

### Custom configuration
1. Write your own configuration in ths file: `config.ini`
```ini
[my-config]
key = value
```
2. Write your own configuration struct in the file: `vars/setting.go`
```go
package vars

type MyConfig struct {
    Key string
}
var MyConfigSetting = &MyConfig{}
```
3. Write setup function in the file: `setup/viper.go`
```go
package setup

func bindSetting(v *viper.Viper) error {
	// ...
		
	if err := v.UnmarshalKey("my-config", vars.MyConfigSetting); err != nil {
		return err
	}
	
	// ...
	return nil
}

```

### Swagger docs init
1. Write description of your API. like:
```go
// GetUser 获取用户信息
// @Summary Get User info
// @Produce  json
// @Param id path int true "user id"
// @Success 200 {object} domain.Response{Data=domain.User}
// @Failure 500 {object} domain.Response{ErrMsg=string}
// @Router /user/:id [get]
func (s userServer) GetUser(c *gin.Context) {
	......
}
```
2. Execute `make api-docs` in terminal to generate swagger docs.

### Logger Usage
can use `vars.Logger` to log. eg:
```go
vars.Logger.Debug("this is debug log.")
vars.Logger.Info("this is info log.", zap.Int64("user_id", userId))
vars.Logger.Warn("this is warn log.")
vars.Logger.Error("this is err log.", zap.Int64("userId", userId), zap.Error(err))

// output:
//{"level":"debug","time":"2022-04-19T16:39:28.652+0800","caller":"server/user_server.go:93","msg":"this is debug log."}
//{"level":"info","time":"2022-04-19T16:39:28.653+0800","caller":"server/user_server.go:94","msg":"this is info log.","user_id":126333}
//{"level":"warn","time":"2022-04-19T16:39:28.653+0800","caller":"server/user_server.go:95","msg":"this is warn log."}
//{"level":"error","time":"2022-04-19T16:33:11.390+0800","caller":"server/user_server.go:98","msg":"get user failed. ","userId":126333,"error":"record not found","stacktrace":"github.com/h8r-dev/platform-backend/server.(*userServer).GetUsername\n\t/home/nocalhost-dev/server/user_server.go:98\ngithub.com/gin-gonic/gin.(*Context).Next\n\t/go/pkg/mod/github.com/gin-gonic/gin@v1.7.7/context.go:168\ngithub.com/Depado/ginprom.(*Prometheus).Instrument.func1\n\t/go/pkg/mod/github.com/!depado/ginprom@v1.7.4/prom.go:349\ngithub.com/gin-gonic/gin.(*Context).Next\n\t/go/pkg/mod/github.com/gin-gonic/gin@v1.7.7/context.go:168\ngithub.com/gin-gonic/gin.CustomRecoveryWithWriter.func1\n\t/go/pkg/mod/github.com/gin-gonic/gin@v1.7.7/recovery.go:99\ngithub.com/gin-gonic/gin.(*Context).Next\n\t/go/pkg/mod/github.com/gin-gonic/gin@v1.7.7/context.go:168\ngithub.com/gin-gonic/gin.LoggerWithConfig.func1\n\t/go/pkg/mod/github.com/gin-gonic/gin@v1.7.7/logger.go:241\ngithub.com/gin-gonic/gin.(*Context).Next\n\t/go/pkg/mod/github.com/gin-gonic/gin@v1.7.7/context.go:168\ngo.opentelemetry.io/contrib/instrumentation/github.com/gin-gonic/gin/otelgin.Middleware.func1\n\t/go/pkg/mod/go.opentelemetry.io/contrib/instrumentation/github.com/gin-gonic/gin/otelgin@v0.31.0/gintrace.go:80\ngithub.com/gin-gonic/gin.(*Context).Next\n\t/go/pkg/mod/github.com/gin-gonic/gin@v1.7.7/context.go:168\ngithub.com/gin-gonic/gin.CustomRecoveryWithWriter.func1\n\t/go/pkg/mod/github.com/gin-gonic/gin@v1.7.7/recovery.go:99\ngithub.com/gin-gonic/gin.(*Context).Next\n\t/go/pkg/mod/github.com/gin-gonic/gin@v1.7.7/context.go:168\ngithub.com/gin-gonic/gin.LoggerWithConfig.func1\n\t/go/pkg/mod/github.com/gin-gonic/gin@v1.7.7/logger.go:241\ngithub.com/gin-gonic/gin.(*Context).Next\n\t/go/pkg/mod/github.com/gin-gonic/gin@v1.7.7/context.go:168\ngithub.com/gin-gonic/gin.(*Engine).handleHTTPRequest\n\t/go/pkg/mod/github.com/gin-gonic/gin@v1.7.7/gin.go:555\ngithub.com/gin-gonic/gin.(*Engine).ServeHTTP\n\t/go/pkg/mod/github.com/gin-gonic/gin@v1.7.7/gin.go:511\nnet/http.serverHandler.ServeHTTP\n\t/usr/local/go/src/net/http/server.go:2887\nnet/http.(*conn).serve\n\t/usr/local/go/src/net/http/server.go:1952"}
//{"level":"error","time":"2022-04-19T16:39:28.654+0800","caller":"server/user_server.go:98","msg":"this is err log.","userId":126333,"error":"record not found",
	//"stacktrace":"github.com/h8r-dev/platform-backend/server.(*userServer).GetUsername\n\t/home/nocalhost-dev/server/user_server.go:98\ngithub.com/gin-gonic/gin.(*Context).Next\n\t/go/pkg/mod/github.com/gin-gonic/gin@v1.7.7/context.go:168\ngithub.com/Depado/ginprom.(*Prometheus).Instrument.func1\n\t/go/pkg/mod/github.com/!depado/ginprom@v1.7.4/prom.go:349\ngithub.com/gin-gonic/gin.(*Context).Next\n\t/go/pkg/mod/github.com/gin-gonic/gin@v1.7.7/context.go:168\ngithub.com/gin-gonic/gin.CustomRecoveryWithWriter.func1\n\t/go/pkg/mod/github.com/gin-gonic/gin@v1.7.7/recovery.go:99\ngithub.com/gin-gonic/gin.(*Context).Next\n\t/go/pkg/mod/github.com/gin-gonic/gin@v1.7.7/context.go:168\ngithub.com/gin-gonic/gin.LoggerWithConfig.func1\n\t/go/pkg/mod/github.com/gin-gonic/gin@v1.7.7/logger.go:241\ngithub.com/gin-gonic/gin.(*Context).Next\n\t/go/pkg/mod/github.com/gin-gonic/gin@v1.7.7/context.go:168\ngo.opentelemetry.io/contrib/instrumentation/github.com/gin-gonic/gin/otelgin.Middleware.func1\n\t/go/pkg/mod/go.opentelemetry.io/contrib/instrumentation/github.com/gin-gonic/gin/otelgin@v0.31.0/gintrace.go:80\ngithub.com/gin-gonic/gin.(*Context).Next\n\t/go/pkg/mod/github.com/gin-gonic/gin@v1.7.7/context.go:168\ngithub.com/gin-gonic/gin.CustomRecoveryWithWriter.func1\n\t/go/pkg/mod/github.com/gin-gonic/gin@v1.7.7/recovery.go:99\ngithub.com/gin-gonic/gin.(*Context).Next\n\t/go/pkg/mod/github.com/gin-gonic/gin@v1.7.7/context.go:168\ngithub.com/gin-gonic/gin.LoggerWithConfig.func1\n\t/go/pkg/mod/github.com/gin-gonic/gin@v1.7.7/logger.go:241\ngithub.com/gin-gonic/gin.(*Context).Next\n\t/go/pkg/mod/github.com/gin-gonic/gin@v1.7.7/context.go:168\ngithub.com/gin-gonic/gin.(*Engine).handleHTTPRequest\n\t/go/pkg/mod/github.com/gin-gonic/gin@v1.7.7/gin.go:555\ngithub.com/gin-gonic/gin.(*Engine).ServeHTTP\n\t/go/pkg/mod/github.com/gin-gonic/gin@v1.7.7/gin.go:511\nnet/http.serverHandler.ServeHTTP\n\t/usr/local/go/src/net/http/server.go:2887\nnet/http.(*conn).serve\n\t/usr/local/go/src/net/http/server.go:1952"}

```

#### Configure
```go
type Zap struct {
	Directory         string // directory to store the log files
	OutputFileEnabled bool // enable output file
}
```

### Database table AutoMigrate
Application run will auto migrate the database table.
```go
func main() {
    //...
	if err := setup.AutoMigrateDB(); err != nil {
        log.Fatalf("setup.AutoMigrateDB() error: %v", err)
    }
	//...
}
```

if you want to add new table, you can add it in the following way.

```go
package domain

type Example struct {
	BaseModel
    Name string
}
```
```go
package setup

func AutoMigrateDB() error {
	if vars.DB == nil {
		return nil
	}

	db := vars.DB

	err := db.AutoMigrate(&domain.User{}, &domain.Example{})
	if err != nil {
		return err
	}

	return nil
}
```
restart application.