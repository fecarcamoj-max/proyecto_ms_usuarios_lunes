
# ----- ETAPA DE COMPILACIÓN -----
FROM maven:3.9.9-eclipse-temurin-21 AS builder

WORKDIR /app

# Descargar dependencias y aprovechar la caché
COPY pom.xml .
RUN mvn -B dependency:go-offline

# Copiar código fuente
COPY src ./src

# Compilar sin ejecutar pruebas
RUN mvn -B clean package -DskipTests

# ----- ETAPA DE EJECUCIÓN -----
FROM eclipse-temurin:21-jre

WORKDIR /app

# Copiar el JAR generado
COPY --from=builder /app/target/*.jar app.jar

# Puerto de la aplicación
EXPOSE 8181

# Ejecutar la aplicación
ENTRYPOINT ["java", "-jar", "app.jar"]
