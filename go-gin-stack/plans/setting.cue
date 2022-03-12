package main

#ingressNginxSetting: #"""
controller:
  service:
    type: LoadBalancer
  metrics:
    enabled: true
  podAnnotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "10254"
"""#

#ingressNginxUpgradeSetting: #"""
controller:
  service:
    type: LoadBalancer
  metrics:
    enabled: true
    serviceMonitor:
      enabled: true
      additionalLabels:
        release: "prometheus"
  podAnnotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "10254"
"""#