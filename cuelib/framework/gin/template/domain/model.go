package domain

import "gorm.io/plugin/soft_delete"

type BaseModel struct {
	Id        int64                 `json:"id" gorm:"primarykey; comment:primary key"`
	CreatedAt int64                 `json:"created_at" gorm:"comment:created time timestamp second"`
	UpdatedAt int64                 `json:"updated_at" gorm:"comment:updated time timestamp second"`
	DeletedAt soft_delete.DeletedAt `json:"-" gorm:"comment:deleted time timestamp second"`
}
