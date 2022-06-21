package scaffoldfactory

import (
	"dagger.io/dagger"
	"github.com/h8r-dev/stacks/chain/factory/basefactory"
)

#Input: {
	scm:          string | *"github"
	organization: string
	repository: [...basefactory.#Repository]
	addons?: [...basefactory.#Addons]
	//cloudProvider:        string | *"kind" | "minikube" | "aws" | "gcp" | "azure" | "alicloud" | "tencent" | "huawei"
	personalAccessToken?: dagger.#Secret
	domain:               basefactory.#DefaultDomain
	appName:              string
	networkType:          string | *"default" | "china_network"
	kubeconfig?:          dagger.#Secret
}
