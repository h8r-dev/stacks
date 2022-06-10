package setup

import (
	"time"

	"github.com/gomodule/redigo/redis"

	"gin-sample/vars"
)

func setupRedis() error {
	if vars.RedisSetting.Host == "" {
		return nil
	}
	vars.RedisConn = &redis.Pool{
		MaxIdle:     vars.RedisSetting.MaxIdle,
		MaxActive:   vars.RedisSetting.MaxActive,
		IdleTimeout: vars.RedisSetting.IdleTimeout,
		Dial: func() (redis.Conn, error) {
			c, err := redis.Dial("tcp", vars.RedisSetting.Host)
			if err != nil {
				return nil, err
			}
			if vars.RedisSetting.Password != "" {
				if _, err := c.Do("AUTH", vars.RedisSetting.Password); err != nil {
					c.Close()
					return nil, err
				}
			}
			return c, err
		},
		TestOnBorrow: func(c redis.Conn, t time.Time) error {
			_, err := c.Do("PING")
			return err
		},
	}

	return nil
}
