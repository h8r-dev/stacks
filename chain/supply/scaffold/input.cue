package scaffold

import (
	"github.com/h8r-dev/chain/supply/base"
)

#Input: {
	scm:          string | *"github"
	organization: string
	repository: [...base.#Repository]
	addons?: [...base.#Addons]
	cloudProvider: string | *"kind" | "minikube" | "aws" | "gcp" | "azure" | "alicloud" | "tencent" | "huawei"
}
