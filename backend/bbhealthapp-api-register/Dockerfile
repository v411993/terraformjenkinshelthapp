FROM eclipse-temurin:8-jre

WORKDIR /app

COPY target/bbhealthapp-api-0.0.1-SNAPSHOT.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
