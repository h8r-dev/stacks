package ingress

import (
	"strings"
	"encoding/yaml"
)

#Ingress: {
	// and generate selectors.
	name: string

	// Namespace to deploy
	namespace: string | *"default"

	// Class name.
	className: string

	// Host name
	hostName: string

	// Path
	path: string

	// Service name
	backendServiceName: string

	// 80 is the default port.
	backendServicePort: int | *80

	// cluster version, such v1, v1beta1
	ingressVersion: string

	// Ingress manifest
	// generate the resource manifest.

	manifest: {
		if strings.TrimSpace(ingressVersion) == "v1" {
			apiVersion: "networking.k8s.io/v1"
			kind:       "Ingress"
			metadata: {
				"name":      name
				"namespace": namespace
				annotations: {
					h8r:  "true"
					host: hostName
				}
			}
			spec: {
				ingressClassName: "nginx"
				rules: [{
					host: hostName
					http: paths: [{
						"path":   path
						pathType: "Prefix"
						backend: service: {
							name: backendServiceName
							port: number: backendServicePort
						}
					}]
				}]
			}
		}
		if strings.TrimSpace(ingressVersion) == "v1beta1" {
			apiVersion: "networking.k8s.io/v1beta1"
			kind:       "Ingress"
			metadata: {
				"name":      name
				"namespace": namespace
				annotations: {
					h8r:                           "true"
					host:                          hostName
					"kubernetes.io/ingress.class": "nginx"
				}
			}
			spec: rules: [{
				host: hostName
				http: paths: [{
					"path":   path
					pathType: "Prefix"
					backend: {
						serviceName: backendServiceName
						servicePort: backendServicePort
					}
				}]
			}]
		}
	}

	// MarshalStream
	manifestStream: yaml.MarshalStream([manifest])
}
