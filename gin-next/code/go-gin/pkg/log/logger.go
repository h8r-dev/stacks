package log

type Logger interface {
	Debug(args ...interface{})
	Info(args ...interface{})
	Warn(args ...interface{})
	Error(args ...interface{})
	Debugf(format string, args ...interface{})
	Infof(format string, args ...interface{})
	Warnf(format string, args ...interface{})
	Errorf(format string, args ...interface{})
}

var Log Logger

func Debug(args ...interface{}) {
	Log.Debug(args)
}

func Info(args ...interface{}) {
	Log.Info(args)
}

func Warn(args ...interface{}) {
	Log.Warn(args)
}

func Error(args ...interface{}) {
	Log.Error(args)
}

func Debugf(format string, args ...interface{}) {
	Log.Debugf(format, args)
}

func Infof(format string, args ...interface{}) {
	Log.Infof(format, args)
}

func Warnf(format string, args ...interface{}) {
	Log.Warnf(format, args)
}

func Errorf(format string, args ...interface{}) {
	Log.Errorf(format, args)
}
