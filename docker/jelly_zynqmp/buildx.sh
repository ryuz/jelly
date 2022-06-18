#!/bin/bash

docker buildx build . --platform linux/arm64/v8 --output=type=docker,dest=- > jelly_zynqmp.tar
