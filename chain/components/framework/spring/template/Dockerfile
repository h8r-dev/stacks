FROM openjdk:18.0.1.1-slim-buster as builder
WORKDIR /home/builder

COPY .mvn .mvn
COPY mvnw .
COPY pom.xml pom.xml

RUN chmod +x mvnw
RUN ./mvnw -B dependency:go-offline

COPY src src

RUN ./mvnw -B package

FROM openjdk:18.0.1.1-slim-buster as runner

WORKDIR /home

COPY --from=builder /home/builder/target/*.jar app.jar

EXPOSE 80

ENTRYPOINT ["java", "-jar", "app.jar"]