package setup

import (
	"fmt"
	"os"

	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
	"gopkg.in/natefinch/lumberjack.v2"

	"gin-sample/log"
	"gin-sample/vars"
)

var (
	// 调试级别
	debugEnabler = zap.LevelEnablerFunc(func(lev zapcore.Level) bool {
		return lev == zap.DebugLevel
	})
	// 日志级别
	infoEnabler = zap.LevelEnablerFunc(func(lev zapcore.Level) bool {
		return lev == zap.InfoLevel
	})
	// 警告级别
	warnEnabler = zap.LevelEnablerFunc(func(lev zapcore.Level) bool {
		return lev == zap.WarnLevel
	})
	// 错误级别
	errorEnabler = zap.LevelEnablerFunc(func(lev zapcore.Level) bool {
		return lev >= zap.ErrorLevel
	})
)

func setupLogger() error {
	coreTree := zapcore.NewTee(
		zapcore.NewCore(getZapEncoder(), getZapWrite(fmt.Sprintf("%s/%s/%s/debug.log", vars.ZapSetting.Directory, vars.AppName, "debug")), debugEnabler),
		zapcore.NewCore(getZapEncoder(), getZapWrite(fmt.Sprintf("%s/%s/%s/info.log", vars.ZapSetting.Directory, vars.AppName, "info")), infoEnabler),
		zapcore.NewCore(getZapEncoder(), getZapWrite(fmt.Sprintf("%s/%s/%s/warning.log", vars.ZapSetting.Directory, vars.AppName, "warning")), warnEnabler),
		zapcore.NewCore(getZapEncoder(), getZapWrite(fmt.Sprintf("%s/%s/%s/error.log", vars.ZapSetting.Directory, vars.AppName, "error")), errorEnabler),
	)

	logger := zap.New(coreTree, zap.AddCaller(), zap.AddStacktrace(errorEnabler))

	log.Logger = logger
	return nil
}

// getZapEncodingConfig 获取zap的编码配置
func getZapEncodingConfig() zapcore.EncoderConfig {
	return zapcore.EncoderConfig{
		TimeKey:        "time",
		LevelKey:       "level",
		NameKey:        "logger",
		CallerKey:      "caller",
		MessageKey:     "msg",
		StacktraceKey:  "stacktrace",
		LineEnding:     zapcore.DefaultLineEnding,
		EncodeLevel:    zapcore.LowercaseLevelEncoder,
		EncodeTime:     zapcore.ISO8601TimeEncoder,
		EncodeDuration: zapcore.SecondsDurationEncoder,
		EncodeCaller:   zapcore.ShortCallerEncoder,
	}
}

// getZapEncoder 获取zap的编码器
func getZapEncoder() zapcore.Encoder {
	return zapcore.NewJSONEncoder(getZapEncodingConfig())
}

// getZapWrite 获取zap的写入器
func getZapWrite(filePath string) zapcore.WriteSyncer {
	if vars.ZapSetting.OutputFileEnabled {
		return zapcore.NewMultiWriteSyncer(zapcore.AddSync(os.Stdout), zapcore.AddSync(&lumberjack.Logger{
			Filename:   filePath,
			MaxSize:    500, // megabytes
			MaxBackups: 200, // number of backups
			MaxAge:     30,  // days
		}))
	}
	return zapcore.AddSync(os.Stdout)
}
