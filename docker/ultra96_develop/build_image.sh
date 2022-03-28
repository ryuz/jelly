#!/bin/bash

mkdir -p config_files
cp ~/.ssh/id_rsa.pub config_files

source make_env.sh

docker-compose build
