# Sample Java Spring Boot Application

## Features
- [springdoc](https://springdoc.org/): swagger, swagger-ui
- [actuator](https://docs.spring.io/spring-boot/docs/current/reference/html/actuator.html#actuator): health, metrics, info

## Monitoring
[http://localhost/health](http://localhost/health)

## Swagger
you can see the swagger UI at [http://localhost/swagger-ui/index.html#](http://localhost/swagger-ui/index.html#)

## Develop
### Run in Docker
- Use docker to deploy the application.
```shell
docker build -t sample .
```
```shell
docker run -p 80:80 sample
```

