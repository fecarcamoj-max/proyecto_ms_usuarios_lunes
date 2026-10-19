
# ----- ETAPA DE COMPILACIÓN -----
FROM maven:3.9.9-eclipse-temurin-21 AS builder

WORKDIR /app

# Copiar primero el archivo de dependencias
COPY pom.xml .

# Descargar las dependencias para aprovechar la caché de Docker
RUN mvn -B dependency:go-offline

# Copiar el código fuente
COPY src ./src

# Compilar el proyecto sin ejecutar pruebas
RUN mvn -B clean package -DskipTests


# ----- ETAPA DE EJECUCIÓN -----
FROM eclipse-temurin:21-jre

WORKDIR /app

# Copiar el JAR generado en la etapa de compilación
COPY --from=builder /app/target/*.jar app.jar

# Puerto de la aplicación
EXPOSE 8181

# Ejecutar la aplicación
ENTRYPOINT ["java", "-jar", "app.jar"]
