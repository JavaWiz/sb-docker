## Spring Boot with Docker
This guide walks you through the process of building a Docker image for running a Spring Boot application.

### What you’ll build
Docker is a Linux container management toolkit with a "social" aspect, allowing users to publish container images and consume those published by others. A Docker image is a recipe for running a containerized process, and in this guide we will build one for a simple Spring boot application.

### What you’ll need

* About 15 minutes

* A favorite text editor or IDE

* JDK 1.8 or later

* Gradle 4+ or Maven 3.2+

If we are NOT using a Linux machine, you will need a virtualized server. By installing VirtualBox, other tools like the Mac’s boot2docker, can seamlessly manage it for you. Visit VirtualBox’s download site and pick the version for your machine. Download and install. Don’t worry about actually running it.

We will also need Docker, which only runs on 64-bit machines. See https://docs.docker.com/installation/#installation for details on setting Docker up for your machine. Before proceeding further, verify you can run docker commands from the shell. If you are using boot2docker you need to run that first.

### Set up a Spring Boot app
Now you can create a simple application.

```
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@SpringBootApplication
@RestController
public class SbDockerApplication {

	@GetMapping("/")
	public String home() {
		return "Hello Docker World";
	}

	public static void main(String[] args) {
		SpringApplication.run(SbDockerApplication.class, args);
	}

}
```

Now we can run the application without the Docker container (i.e. in the host OS).

If we are using Maven, execute:

```
mvn clean package && java -jar target/sb-docker-1.0.jar
```

and go to [localhost:8080](localhost:8080) to see your "Hello Docker World" message.

### Containerize It
Docker has a simple "Dockerfile" file format that it uses to specify the "layers" of an image. So let’s go ahead and create a Dockerfile in our Spring Boot project:

```
FROM openjdk:8-jdk-alpine
ARG JAR_FILE=target/*.jar
COPY ${JAR_FILE} sb-docker.jar
ENTRYPOINT ["java","-jar","/sb-docker.jar"]
```

We can run it (if we are using Maven) with

```
docker build -t springio/sb-docker .
```

This command builds an image and tags it as springio/sb-docker.

This Dockerfile is very simple, but that’s all we need to run a Spring Boot app with no frills: just Java and a JAR file. The build will create a spring user and a spring group to run the application. It will then COPY the project JAR file into the container as "app.jar" that will be executed in the ENTRYPOINT. The array form of the Dockerfile ENTRYPOINT is used so that there is no shell wrapping the java process. The Topical Guide on Docker goes into this topic in more detail.

Running applications with user privileges helps to mitigate some risks (see for example a thread on StackExchange). So, an important improvement to the Dockerfile is to run the app as a non-root user:

```
FROM openjdk:8-jdk-alpine
RUN addgroup -S spring && adduser -S spring -G spring
USER spring:spring
ARG JAR_FILE=target/*.jar
COPY ${JAR_FILE} sb-docker.jar
ENTRYPOINT ["java","-jar","/sb-docker.jar"]
```

If we get that right, it already contains a BOOT-INF/lib directory with the dependency jars in it, and a BOOT-INF/classes directory with the application classes in it. Notice that we are using the application’s own main class com.javawiz.SbDockerApplication (this is faster than using the indirection provided by the fat jar launcher).

To build the image you can use the Docker command line. For example:

```
docker build -t springio/sb-docker .
```

you can run it like this

```
docker run -p 8080:8080 springio/sb-docker
```

We can see the username in the application startup logs (note the "started by" in the first INFO log):
```
2020-07-31 05:17:00.810  INFO 1 --- [main] com.javawiz.SbDockerApplication: Starting SbDockerApplication v1.0 on b14564ea4245 with PID 1 (/sb-docker.jar started by spring in /)
```
Also, there is a clean separation between dependencies and application resources in a Spring Boot fat jar file, and we can use that fact to improve performance. The key is to create layers in the container filesystem. The layers are cached both at build time and at runtime (in most runtimes) so we want the most frequently changing resources, usually the class and static resources in the application itself, to be layered after the more slowly changing resources. Thus we will use a slightly different implementation of the Dockerfile:
```
FROM openjdk:8-jdk-alpine
RUN addgroup -S spring && adduser -S spring -G spring
USER spring:spring
ARG DEPENDENCY=target/dependency
COPY ${DEPENDENCY}/BOOT-INF/lib /sb-docker/lib
COPY ${DEPENDENCY}/META-INF /sb-docker/META-INF
COPY ${DEPENDENCY}/BOOT-INF/classes /sb-docker
ENTRYPOINT ["java","-cp","sb-docker:sb-docker/lib/*","com.javawiz.SbDockerApplication"]
```
We can stop the container after test using docker command:
```
docker contailer ls
docker stop container_id
or 
docker kill container_id
```



