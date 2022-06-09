package registry

import (
	"github.com/h8r-dev/stacks/cuelib/framework/gin"
	"github.com/h8r-dev/stacks/cuelib/framework/next"
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
