#!/bin/bash

docker buildx build . \
    --platform linux/arm64/v8 \
    --output=type=image \
    --tag ryuz88/jelly_zynqmp

