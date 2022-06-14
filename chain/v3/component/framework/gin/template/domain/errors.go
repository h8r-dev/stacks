package domain

import (
	"errors"
	"net/http"
)

var (
	ErrUserAlreadyExists        = NewCustomError(http.StatusConflict, "", errors.New("user already exists"))
	ValidParamsFailed           = NewCustomError(http.StatusBadRequest, "", errors.New("validation failed"))
	AccessTokenNotFound         = NewCustomError(http.StatusUnauthorized, "", errors.New("access token not found"))
	UserNotActive               = NewCustomError(http.StatusForbidden, "", errors.New("user not active"))
	ErrOrganizationExists       = NewCustomError(http.StatusConflict, "", errors.New("organization already exists"))
	ErrOrganizationMemberExists = NewCustomError(http.StatusConflict, "", errors.New("organization member already exists"))
	NotAuthorized               = NewCustomError(http.StatusForbidden, "", errors.New("not authorized"))
)

type CustomError struct {
	error
	Code int
	Msg  string
}

func NewCustomError(code int, msg string, err error) *CustomError {
	return &CustomError{
		error: err,
		Msg:   msg,
		Code:  code,
	}
}
