package framework

import (
	"github.com/h8r-dev/stacks/cuelib/component/framework/gin"
	"github.com/h8r-dev/stacks/cuelib/component/framework/next"
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
