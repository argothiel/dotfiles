#!/bin/sh

cd "$(dirname $0)"

. /etc/os-release

case $ID in
  ubuntu) ./install-ubuntu.sh
    ;;

  arch) echo "This is Arch Linux!"
    ;;

  centos) echo "This is CentOS!"
    ;;

  *) echo "This is an unknown distribution."
      ;;
esac

su -c ./install-common-root.sh

