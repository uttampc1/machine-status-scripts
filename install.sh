#!/bin/bash
sudo echo "Installing template and creating symlinks in /usr/local directory"
if [ -r /etc/motd ]; then
  echo "File is readable"
  if [ -w /etc/motd ]; then
    echo "File is readable"
  fi
else
  sudo touch /etc/motd
fi
sudo chmod 666 /etc/motd
sudo cp ./machine-status /usr/local/bin
sudo chmod 555 ./machine-status /usr/local/bin
sudo ln -s /usr/local/bin/machine-status /usr/local/bin/machine-release
sudo ln -s /usr/local/bin/machine-status /usr/local/bin/machine-reserve
machine-release
