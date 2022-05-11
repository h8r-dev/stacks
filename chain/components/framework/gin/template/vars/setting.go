package vars

import (
	"time"
)

type Server struct {
	RunMode      string
	HttpPort     int
	ReadTimeout  time.Duration
	WriteTimeout time.Duration
}

var ServerSetting = &Server{}

type Database struct {
	Type         string
	User         string
	Password     string
	Host         string
	Name         string
	TablePrefix  string
	MaxIdleConns int
	MaxOpenConns int
}

var DatabaseSetting = &Database{}

type Redis struct {
	Host        string
	Password    string
	MaxIdle     int
	MaxActive   int
	IdleTimeout time.Duration
}

var RedisSetting = &Redis{}

type Zap struct {
	Directory         string
	OutputFileEnabled bool
}

var ZapSetting = &Zap{}

type Jwt struct {
	Lookup    string
	TokenType string
	Secret    string
	Expire    time.Duration
}

var JwtSetting = &Jwt{}
