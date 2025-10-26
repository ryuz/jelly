

GITHUB_USER = ryuz
GITHUB_REPO = jelly
IMAGE_NAME  = ghcr.io/$(GITHUB_USER)/$(GITHUB_REPO)/jelly-devcontainer-ubuntu24
IMAGE_TAG   = 0.0.2

.PHONY: all
all: build

.PHONY: build
build:
	docker build -t $(IMAGE_NAME):$(IMAGE_TAG) .
	docker tag $(IMAGE_NAME):$(IMAGE_TAG) $(IMAGE_NAME):latest

.PHONY: push
push: build
	cat ~/ghcr.txt | docker login ghcr.io -u $(GITHUB_USER) --password-stdin
	docker push $(IMAGE_NAME):$(IMAGE_TAG)
	docker push $(IMAGE_NAME):latest
