package cache

type CommonCache interface {
	// Get user by id
	Get(userid int64) (string, bool, error)
	// Set user
	Set(userid int64, username string) error
}
