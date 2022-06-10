package vars

import (
	"github.com/gomodule/redigo/redis"
	"gorm.io/gorm"
)

const (
	// ConfigFile is the path to the config file
	ConfigFile = "config.ini"
	// AppName is the name of the application
	AppName = "gin-sample"
)

var (
	DB        *gorm.DB
	RedisConn *redis.Pool
)
