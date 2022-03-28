#!/bin/bash

USER_NAME=${LOCAL_USER:-user}
USER_ID=${LOCAL_UID:-9001}
GROUP_ID=${LOCAL_GID:-9001}

echo "Starting with UID : $USER_ID, GID: $GROUP_ID"
useradd -u $USER_ID -o -m $USER_NAME --shell /usr/bin/bash
groupmod -g $USER_NAME $GROUP_ID
echo "$USER_NAME:$USER_NAME" | chpasswd

gpasswd -a $USER_NAME sudo

/usr/sbin/sshd -D
