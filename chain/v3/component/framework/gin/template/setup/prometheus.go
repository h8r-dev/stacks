package setup

import (
	"github.com/penglongli/gin-metrics/ginmetrics"

	"gin-sample/vars"
)

func setupPrometheus() {
	// get global Monitor object
	m := ginmetrics.GetMonitor()
	// +optional set metric path, default /debug/metrics
	m.SetMetricPath("/metrics")
	vars.Prometheus = m
}
