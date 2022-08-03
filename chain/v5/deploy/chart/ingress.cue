package chart

#Ingress: {
	input: {
		className: string | *"nginx"
		rewrite:   bool
		host:      string
		pathType:  string | *"ImplementationSpecific"
		paths: [...]
	}
	_rewrite: input.rewrite
	info: {
		enabled:   true
		className: input.className
		if _rewrite {
			annotations: "nginx.ingress.kubernetes.io/rewrite-target": "/$2"
		}
		if !_rewrite {
			annotations: {}
		}
		hosts: [{
			host: input.host
			paths: [
				for p in input.paths {
					if _rewrite {
						path: p.path + "(/|$)(.*)"
					}
					if !_rewrite {
						path: p.path
					}
					pathType: input.pathType
				},
			]
		}]
		tls: []
	}
}
