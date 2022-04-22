package log

import "go.uber.org/zap"

func init() {
	logger, _ := zap.NewDevelopment()
	Log = logger.Sugar()
}
