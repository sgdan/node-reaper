# node-reaper

Provides simple UI for EC2 instances in an AWS account
to be manually started(or extended) for a 4 hour uptime window. This is
similar to the kubernetes [pod-reaper](https://github.com/sgdan/pod-reaper)
but a lot simpler.

Front end is using [Elm](https://elm-lang.org/) which communicates via
JSON messages with the back end which is a [Micronaut](https://micronaut.io/)
service written in [Kotlin](https://kotlinlang.org/).

Only EC2 instances with a "reaper-enable" tag set to "true" will be
displayed in the UI. When an instance is started its "reaper-timestamp"
tag will be set to that moment (in UTC milliseconds). When an instance
is "extended" that timestamp gets reset. If 4 hours elapses with no
extensions the instance will be stopped.

## Running

To build and run the docker container, use `make run` then go to
[http://localhost:8080](http://localhost:8080) for the UI.

Credentials for AWS access will be looked up in the default way
by the SDK.
See https://docs.aws.amazon.com/sdk-for-java/v2/developer-guide/credentials.html

## Development

Assumes frontend tools have already been installed locally e.g.

```bash
yarn global add create-elm-app
yarn global add elm-test
yarn global add elm
```

1. Run the back end using `make backend-dev`
2. Run the front end using `make frontend-dev`
3. Go to [http://localhost:3000](http://localhost:3000) in your browser to
   test. The UI will automatically reload when front end code is changed.

For front end unit tests run `make frontend-test`.

- Front end is written in [Elm](https://elm-lang.org/)
- Using [Create Elm App](https://github.com/halfzebra/create-elm-app)
- Icon generated with [https://favicon.io/favicon-generator/](https://favicon.io/favicon-generator/)
- Back end using [Micronaut](https://micronaut.io/) and [Kotlin](https://kotlinlang.org/)
