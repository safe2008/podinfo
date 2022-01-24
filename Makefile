OWNER := safe2008
PROJECT := podinfo
VERSION := 1.2.1
OPV := $(OWNER)/$(PROJECT):$(VERSION)
WEBPORT := 8080:8080

# you may need to change to "sudo docker" if not a member of 'docker' group
DOCKERCMD := "docker"

BUILD_TIME := $(shell date -u '+%Y-%m-%d_%H:%M:%S')
# unique id from last git commit
MY_GITREF := $(shell git rev-parse --short HEAD)

## builds docker image
docker-build:
	echo MY_GITREF is $(MY_GITREF)
	$(DOCKERCMD) build --build-arg MY_VERSION=$(VERSION) --build-arg MY_BUILDTIME=$(BUILD_TIME) -f Dockerfile -t $(OPV) .

## cleans docker image
clean:
	$(DOCKERCMD) image rm $(OPV) | true

## runs container in foreground, testing a couple of override values
docker-test-fg:
	$(DOCKERCMD) run -it -p $(WEBPORT) --rm $(OPV)

## runs container in foreground, override entrypoint to use use shell
docker-test-cli:
	$(DOCKERCMD) run -it --rm --entrypoint "/bin/sh" $(OPV)

## run container in background
docker-run-bg:
	$(DOCKERCMD) run -d -p $(WEBPORT) --rm --name $(PROJECT) $(OPV)

## get into console of container running in background
docker-cli-bg:
	$(DOCKERCMD) exec -it $(PROJECT) /bin/sh

## tails $(DOCKERCMD)logs
docker-logs:
	$(DOCKERCMD) logs -f $(PROJECT)

## stops container running in background
docker-stop:
	$(DOCKERCMD) stop $(PROJECT)


## pushes to $(DOCKERCMD)hub
docker-push:
	$(DOCKERCMD) push $(OPV)

commitlint:
	@echo "Install commitlint"
	npm install --save-dev @commitlint/{cli,config-conventional}
	echo "module.exports = { extends: ['@commitlint/config-conventional'] };" > commitlint.config.js
	@echo "Install Husky v6"
	npm install husky --save-dev
	@echo "Active hooks"
	npx husky install
	@echo "Add hook" 
	npx husky add .husky/commit-msg 'npx --no -- commitlint --edit $1'

testlint:
	git commit -m "foo: this will fail"

commit:
	git status
	git add .
	git commit -m "feat: add new update"

