package setup

func Setup() error {
	// setup viper to read config
	if _, err := setupViper(); err != nil {
		return err
	}

	// setup logger
	if err := setupLogger(); err != nil {
		return err
	}

	// setup database
	if err := setupDB(); err != nil {
		return err
	}

	// setup redis
	if err := setupRedis(); err != nil {
		return err
	}

	// setup prometheus
	setupPrometheus()
	return nil
}
