package tools

import (
	nginxKind "github.com/h8r-dev/chain/ingress/nginx/kind"
	nginxCloud "github.com/h8r-dev/chain/ingress/nginx/cloud"
	"github.com/h8r-dev/chain/argocd"
)

#Instance: {
	tools: {
		"argocd":      argocd
		"nginx.kind":  nginxKind
		"nginx.cloud": nginxCloud
	}

	input: #Input

	do: {
		for i in input.tools {
			"\(i.name)": tools[i.name].#Instance & {
				"input": tools[i.name].#Input & {
					"kubeconfig": input.kubeconfig
					"version":    i.version
				}
			}
		}
	}

	// output: #Output & {
	//  image:   install.output
	//  success: install.success
	// }
}
