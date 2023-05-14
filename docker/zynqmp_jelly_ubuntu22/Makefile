
.PHONY: all
all:

.PHONY: buildx
buildx: Dockerfile
	sh -e ./files/download.sh
	docker buildx build . --platform linux/arm64/v8 --tag ryuz88/zynqmp_jelly_ubuntu22.04 --output=type=docker,dest=- > zynqmp_jelly_ubuntu22.04.tar

.PHONY: pushx
pushx: Dockerfile
	sh -e ./files/download.sh
	docker buildx build . --platform linux/arm64/v8 --tag ryuz88/zynqmp_jelly_ubuntu22.04 --output=type=image,push=true
