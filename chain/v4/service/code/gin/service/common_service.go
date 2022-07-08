package service

import "gin-sample/domain"

type commonServiceImpl struct {
}

func (c *commonServiceImpl) GetName() string {
	return "common"
}

func NewCommonService() domain.CommonService {
	return &commonServiceImpl{}
}
