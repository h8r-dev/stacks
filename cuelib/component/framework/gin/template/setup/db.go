package setup

import (
	"fmt"
	"strings"

	"gorm.io/driver/mysql"
	"gorm.io/gorm"

	"gin-sample/vars"
)

func setupDB() error {
	if vars.DatabaseSetting.Host == "" {
		return nil
	}

	dsn := fmt.Sprintf("%s:%s@tcp(%s)/%s?charset=utf8&parseTime=True&loc=Local",
		vars.DatabaseSetting.User,
		vars.DatabaseSetting.Password,
		vars.DatabaseSetting.Host,
		vars.DatabaseSetting.Name)

	dialector, ok := getDialect(vars.DatabaseSetting.Type, dsn)
	if !ok {
		return fmt.Errorf("unsupported database type: %s", vars.DatabaseSetting.Type)
	}
	db, err := gorm.Open(dialector, &gorm.Config{
		DisableForeignKeyConstraintWhenMigrating: true, // 禁用自动创建外键约束
	})
	if err != nil {
		return err
	}

	sqlDB, err := db.DB()
	if err != nil {
		return err
	}
	sqlDB.SetMaxIdleConns(vars.DatabaseSetting.MaxIdleConns)
	sqlDB.SetMaxOpenConns(vars.DatabaseSetting.MaxOpenConns)

	vars.DB = db
	return nil
}

// getDialect returns the dialector according to the database type
func getDialect(name string, dsn string) (gorm.Dialector, bool) {
	switch strings.ToLower(name) {
	case "mysql":
		return mysql.New(mysql.Config{
			DSN: dsn,
		}), true
	default:
		return nil, false
	}
}

func AutoMigrateDB() error {
	if vars.DB == nil {
		return nil
	}

	db := vars.DB

	err := db.AutoMigrate()
	if err != nil {
		return err
	}

	return nil
}
