#!/bin/sh

apt update

ln -fs /usr/share/zoneinfo/Europe/Warsaw /etc/localtime
DEBIAN_FRONTEND=noninteractive apt -y install bash colortest curl fish fzf git git-delta grep libfuse2 lsd nfs-common podman putty-tools python-is-python3 python3-pip rclone ripgrep tzdata wget \
  clang clangd g++ gdb \
  golang-go ruby nodejs npm
