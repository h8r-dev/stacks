package setup

import (
	"fmt"

	"github.com/fsnotify/fsnotify"
	"github.com/spf13/viper"

	"gin-sample/vars"
)

func setupViper() (*viper.Viper, error) {
	v := viper.New()
	v.SetConfigFile(vars.ConfigFile)
	if err := v.ReadInConfig(); err != nil {
		return nil, err
	}

	if err := bindSetting(v); err != nil {
		return nil, err
	}

	v.WatchConfig()

	v.OnConfigChange(func(e fsnotify.Event) {
		fmt.Println("Config file changed:", e.Name)
		if err := bindSetting(v); err != nil {
			fmt.Println("Update config err:", err)
		}
	})

	if err := bindSetting(v); err != nil {
		return nil, err
	}
	return v, nil
}

func bindSetting(v *viper.Viper) error {
	if err := v.UnmarshalKey("server", vars.ServerSetting); err != nil {
		return err
	}

	if err := v.UnmarshalKey("database", vars.DatabaseSetting); err != nil {
		return err
	}

	if err := v.UnmarshalKey("redis", vars.RedisSetting); err != nil {
		return err
	}

	if err := v.UnmarshalKey("zap", vars.ZapSetting); err != nil {
		return err
	}

	if err := v.UnmarshalKey("jwt", vars.JwtSetting); err != nil {
		return err
	}

	return nil
}
