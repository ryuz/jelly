#!/bin/bash

set -eu
cat <<EOT > .env
LOCAL_USER=`whoami`
LOCAL_UID=`id -u`
LOCAL_GID=`id -g`
EOT
