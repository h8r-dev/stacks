package framework

import (
	"github.com/h8r-dev/stacks/chain/v3/component/framework/gin"
	"github.com/h8r-dev/stacks/chain/v3/component/framework/next"
)

#Init: {
	name: "gin"
	gin.#Init
} | {
	name: "next"
	next.#Init
}

#Config: {
	name: "gin"
	gin.#Config
} | {
	name: "next"
	next.#Config
}
