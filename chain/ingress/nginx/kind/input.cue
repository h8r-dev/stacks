package kind

import (
	"dagger.io/dagger"
)

#Input: {
	namespace:  "ingress-nginx"
	version:    string | *"helm-chart-4.0.19"
	url:        string | *"https://raw.githubusercontent.com/kubernetes/ingress-nginx/\(version)/deploy/static/provider/kind/deploy.yaml"
	kubeconfig: dagger.#Secret
	waitFor:    bool | *true
}
