package domain

import (
	"fmt"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/go-playground/validator/v10"
)

const (
	SuccessCode      = 200
	FailCode         = 500
	InvalidParamCode = 400
)

func GetErrMsgByCode(code int) string {
	switch code {
	case SuccessCode:
		return "success"
	case FailCode:
		return "fail"
	case InvalidParamCode:
		return "invalid param"
	default:
		return "unknown error"
	}
}

type ErrResponse struct {
	Msg    string `json:"msg,omitempty"`
	ErrMsg string `json:"err_msg,omitempty"`
}

func Success(c *gin.Context) {
	c.JSON(http.StatusNoContent, nil)
}

func SuccessData(c *gin.Context, data interface{}) {
	c.JSON(SuccessCode, data)
}

func SuccessCreated(c *gin.Context, data interface{}) {
	c.JSON(http.StatusCreated, data)
}

func SuccessPagination(c *gin.Context, data interface{}, total int64, pageTotal int64) {
	c.Header("X-Total-Count", fmt.Sprintf("%d", total))
	c.Header("X-Page-Total", fmt.Sprintf("%d", pageTotal))
	c.JSON(SuccessCode, data)
}

func Fail(c *gin.Context) {
	c.JSON(FailCode, ErrResponse{
		ErrMsg: "Internal Server Error",
	})
}

func FailWithErr(c *gin.Context, err error) {
	if e, ok := err.(*CustomError); ok {
		c.JSON(e.Code, ErrResponse{
			Msg:    e.Msg,
			ErrMsg: e.error.Error(),
		})
	} else if e, ok := err.(validator.ValidationErrors); ok {
		errMsg := make([]string, 0, len(e))
		for _, v := range e {
			errMsg = append(errMsg, fmt.Sprintf("%s type:%s, value:%s", v.StructNamespace(), v.Tag(), v.Value()))
		}
		c.JSON(InvalidParamCode, ErrResponse{
			Msg:    "invalid param",
			ErrMsg: strings.Join(errMsg, ";"),
		})
	} else {
		c.JSON(FailCode, ErrResponse{
			ErrMsg: err.Error(),
		})
	}
}

func FailWithErrMsg(c *gin.Context, errMsg string) {
	c.JSON(FailCode, ErrResponse{
		ErrMsg: errMsg,
	})
}

func FailWithCodeMsg(c *gin.Context, code int, errMsg string) {
	c.JSON(code, ErrResponse{
		ErrMsg: errMsg,
	})
}

func FailWithErrAndMsg(c *gin.Context, err error, msg string) {
	if e, ok := err.(*CustomError); ok {
		c.JSON(e.Code, ErrResponse{
			Msg:    msg,
			ErrMsg: e.error.Error(),
		})
	} else {
		c.JSON(FailCode, ErrResponse{
			Msg:    msg,
			ErrMsg: err.Error(),
		})
	}
}
