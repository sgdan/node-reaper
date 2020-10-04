frontend=@docker-compose run --rm -p 3000:3000 frontend
backend=@docker-compose run --rm -p 8080:8080 backend

# build and run using docker
.build: Dockerfile
	docker build --target frontend-dev -t node-reaper-frontend .
	docker build --target backend-dev -t node-reaper-backend .
	docker build . -t node-reaper
	touch .build

run: .build
	@docker run --rm -it -v ~/.aws:/root/.aws -p 8080:8080 node-reaper

shell: .build
	@docker run --rm -it node-reaper sh


# for local development, start front and back end separately
frontend-dev: .build
	$(frontend) elm-app start

backend-dev: .build
	$(backend) gradle run


# unit testing
frontend-test: .build
	$(frontend) elm-test

backend-test: .build
	$(backend) gradle test


# shells for dev/debugging
frontend-shell: .build
	$(frontend) bash

backend-shell: .build
	$(backend) bash
