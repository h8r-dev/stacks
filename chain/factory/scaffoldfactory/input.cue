package scaffoldfactory

import (
	"github.com/h8r-dev/stacks/chain/factory/basefactory"
	"dagger.io/dagger"
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
}
