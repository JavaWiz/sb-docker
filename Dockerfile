FROM openjdk:8-jdk-alpine
RUN addgroup -S spring && adduser -S spring -G spring
USER spring:spring
ARG DEPENDENCY=target/dependency
COPY ${DEPENDENCY}/BOOT-INF/lib /sb-docker/lib
COPY ${DEPENDENCY}/META-INF /sb-docker/META-INF
COPY ${DEPENDENCY}/BOOT-INF/classes /sb-docker
ENTRYPOINT ["java","-cp","sb-docker:sb-docker/lib/*","com.javawiz.SbDockerApplication"]