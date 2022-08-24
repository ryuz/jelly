
.PHONY: all
all:

.PHONY: buildx
buildx: Dockerfile
	docker buildx build . --platform linux/arm64/v8 --tag ryuz88/zynqmp_ros2_foxy --output=type=docker,dest=- > zynqmp_ros2_foxy.tar

.PHONY: pushx
pushx: Dockerfile
	docker buildx build . --platform linux/arm64/v8 --tag ryuz88/zynqmp_ros2_foxy --output=type=image,push=true
