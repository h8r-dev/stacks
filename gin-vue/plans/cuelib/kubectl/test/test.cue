package kubectl

import (
	"dagger.io/dagger"
	"github.com/h8r-dev/gin-vue/plans/cuelib/kubectl"
)

testyaml: #"""
	apiVersion: apps/v1
	kind: Deployment
	metadata:
	  creationTimestamp: null
	  labels:
	    app: my-dep
	  name: my-dep
	spec:
	  replicas: 1
	  selector:
	    matchLabels:
	      app: my-dep
	  strategy: {}
	  template:
	    metadata:
	      creationTimestamp: null
	      labels:
	        app: my-dep
	    spec:
	      containers:
	      - image: nginx
	        name: nginx
	        resources: {}
	status: {}
	"""#

dagger.#Plan & {
	client: {
		filesystem: code: read: contents: dagger.#FS
		commands: kubeconfig: {
			name: "cat"
			args: ["\(env.KUBECONFIG)"]
			stdout: dagger.#Secret
		}
		env: KUBECONFIG: string
	}

	actions: apply: kubectl.#Apply & {
		manifest:   testyaml
		namespace:  "test-01"
		kubeconfig: client.commands.kubeconfig.stdout
	}
}
