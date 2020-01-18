# Front end: Elm
FROM node:12.12.0 as frontend
RUN yarn global add create-elm-app@4.1.2
WORKDIR /app
COPY frontend/elm.json .
COPY frontend/public public/
COPY frontend/src src/
RUN ELM_APP_URL=/reaper/ elm-app build

# Back end: Micronaut/Kotlin/Gradle -> GraalVM native executable
# FROM oracle/graalvm-ce:19.3.1-java11 as backend
# ARG GRADLE_VERSION=6.0.1
# RUN mkdir -p /opt/gradle && cd /opt/gradle \
#     && curl -o gradle.zip -Ls \
#     https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip \
#     && jar xf gradle.zip \
#     && chmod +x gradle-${GRADLE_VERSION}/bin/gradle \
#     && ln -s /opt/gradle/gradle-${GRADLE_VERSION}/bin/gradle /usr/local/bin/gradle \
#     && rm gradle.zip
# RUN gu install native-image
# WORKDIR /nodereaper
# COPY build.gradle .
# COPY settings.gradle .
# COPY gradle.properties .
# change gradle home folder so cache will be preserved
# RUN gradle -g . shadowJar clean
# COPY src src
# RUN gradle -g . shadowJar

# RUN gradle -g . installShadowDist
# ARG LIB=build/install/node-reaper-shadow/lib
# RUN native-image --no-fallback \
#     -cp $LIB/node-reaper-0.1-SNAPSHOT-all.jar \
#     org.sgdan.nodereaper.Application \
#     build/node-reaper-native

# RUN gradle -g . installDist
# ARG LIB=build/install/node-reaper/lib
# RUN native-image --no-fallback --allow-incomplete-classpath \
#     -cp $LIB/node-reaper-0.1-SNAPSHOT.jar:$LIB/kotlin-stdlib-common-1.3.61 \
#     org.sgdan.nodereaper.Application \
#     build/node-reaper-native


# Back end: Micronaut/Kotlin/Gradle
FROM gradle:6.0.1 as backend
WORKDIR /nodereaper
COPY build.gradle .
COPY settings.gradle .
COPY gradle.properties .
# change gradle home folder so cache will be preserved
RUN gradle -g . shadowJar clean
COPY src src
RUN gradle -g . shadowJar
# e.g. /nodereaper/build/libs/node-reaper-1.0-SNAPSHOT-all.jar

# Final image: OpenJDK
FROM adoptopenjdk/openjdk13:jre-13.0.1_9-alpine
WORKDIR /nodereaper
COPY --from=frontend /app/build ./ui
COPY --from=backend /nodereaper/build/libs/node-reaper-*-all.jar node-reaper.jar
ENV CORS_ENABLED false
CMD ["java", "-jar", "node-reaper.jar"]

# Final image: Alpine
# FROM alpine:3.11.3
# WORKDIR /nodereaper
# COPY --from=frontend /app/build ./ui
# COPY --from=backend /nodereaper/build/node-reaper-native node-reaper-native
# ENV CORS_ENABLED false
# CMD ["node-reaper-native"]
