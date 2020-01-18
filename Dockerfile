# Front end: Elm
FROM node:12.12.0 as frontend
RUN yarn global add create-elm-app@4.1.2
WORKDIR /app
COPY frontend/elm.json .
COPY frontend/public public/
COPY frontend/src src/
RUN ELM_APP_URL=/reaper/ elm-app build

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
