package middleware

#Init: {
	args: _
	for m in args.middleware {
		(m.name): #Config & m
	}
}

#Config: {
	{
		type: "postgres"
	} | {
		type: "redis"
	}
	...
}
