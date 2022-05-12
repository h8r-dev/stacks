package middleware

import (
	"strconv"

	"github.com/gin-gonic/gin"
)

const (
	Page            = "page"
	PageSize        = "page_size"
	PageDefault     = 1
	PageSizeDefault = 10
)

// PaginationMiddleware pagination is a middleware that adds pagination to the context
func PaginationMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		page, err := strconv.ParseInt(c.Query(Page), 10, 64)
		if err != nil {
			page = PageDefault
		}

		pageSize, err := strconv.ParseInt(c.Query(PageSize), 10, 64)
		if err != nil {
			pageSize = PageSizeDefault
		}

		c.Set(Page, page)
		c.Set(PageSize, pageSize)

		c.Next()
	}
}
