
.PHONY: all
all:

.PHONY: buildx
buildx: Dockerfile
	sh -e ./files/download.sh
	docker buildx build . --platform linux/arm64/v8 --tag ryuz88/zynqmp_jelly --output=type=docker,dest=- > zynqmp_jelly.tar

.PHONY: pushx
pushx: Dockerfile
	sh -e ./files/download.sh
	docker buildx build . --platform linux/arm64/v8 --tag ryuz88/zynqmp_jelly --output=type=image,push=true
