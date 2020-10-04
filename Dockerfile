# Front end: Elm
FROM node:14.12.0-alpine3.12 as frontend-dev
RUN apk upgrade \
    && apk --no-cache add bash
RUN yarn global add create-elm-app@5.2.0
RUN yarn global add elm-test@0.19.1-revision4
RUN yarn global add elm@0.19.1-3

FROM frontend-dev as frontend
WORKDIR /app
COPY frontend/elm.json .
COPY frontend/public public/
COPY frontend/src src/
RUN ELM_APP_URL=/reaper/ elm-app build

# Back end: Micronaut/Kotlin/Gradle
FROM gradle:6.6.1-jre14 as backend-dev

FROM backend-dev as backend
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
FROM adoptopenjdk:14-jre-openj9
WORKDIR /nodereaper
COPY --from=frontend /app/build ./ui
COPY --from=backend /nodereaper/build/libs/node-reaper-*-all.jar node-reaper.jar
ENV CORS_ENABLED false
CMD ["java", "-jar", "node-reaper.jar"]
