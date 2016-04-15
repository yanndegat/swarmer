TAG = $(shell date +%Y-%m-%d-%H%M%S)
IMAGE ?= registry.service.swarmer:5000/graylog-server

GRAYLOG_VERSION ?= "1.3.4"

help:
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##//'

graylog-server.tgz: ## Downloads the graylog server package
	wget -O ./graylog-server.tgz https://packages.graylog2.org/releases/graylog2-server/graylog-${GRAYLOG_VERSION}.tgz

git-pull: ## Pull the latest changes from the remote GIT repository
git-pull:
	git pull

build: ## same as build-no-cache
build: test graylog-server.tgz
	docker build --pull=true -t $(IMAGE):$(TAG) .
	echo $(TAG) > .last_tag

build-no-pull: ## git-pull build using local cache not to pulling a fresh image from docker repository
build-no-pull: test git-pull graylog-server.tgz
	docker build -f -t $(IMAGE):$(TAG) .
	echo $(TAG) > .last_tag

build-no-cache: ## git-pull and build IGNORING local cache and force to pull a fresh image from docker repository
build-no-cache: test git-pull graylog-server.tgz
	docker build --no-cache --pull=true -t $(IMAGE):$(TAG) .
	echo $(TAG) > .last_tag

push: ##  Push last generated build
push: test
	test -s .last_tag || (echo You need to build first ; exit 1)
	docker push $(IMAGE):`cat .last_tag` && \
	rm -f .last_tag

push-latest: ## Push local latest tag
push-latest: test
	docker push $(IMAGE):latest

latest: ## Link last build (tag) to the tag latest
latest: test build
	test -s .last_tag || (echo You need to build first ; exit 1)
	docker tag -f $(IMAGE):`cat .last_tag` $(IMAGE):latest

test: ##  Run necessary tests
	@test -n "$(IMAGE)" || (echo TEST ERROR: You MUST specify IMAGE variable, type make help ; exit 1)
	@test -f ./Dockerfile || (echo TEST ERROR: There is no Dockerfile.$(IMAGE) in this directory. ; exit 1)
