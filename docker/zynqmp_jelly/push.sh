#!/bin/bash

docker buildx build . --platform linux/arm64/v8 --tag ryuz88/zynqmp_jelly --output=type=image,push=true

