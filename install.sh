#!/bin/bash
sudo echo "Installing template and creating symlinks in /usr/local directory"
if [ ! -f /etc/motd ]; then
  echo
  echo "It seems /etc/motd file is not a regular file."
  echo "Please make sure we can create it as a regular file"
  echo
  exit
fi

sudo touch /var/log/machine-status.log
sudo chmod 666 /var/log/machine-status.log
sudo touch /etc/motd
sudo chmod 666 /etc/motd

sudo /bin/rm /usr/local/bin/machine-status /usr/local/bin/machine-release /usr/local/bin/machine-reserve /usr/local/bin/machine-report
sudo cp ./machine-status /usr/local/bin
sudo cp ./motd.template /usr/local/etc
sudo chmod 555 ./machine-status /usr/local/bin
sudo ln -s /usr/local/bin/machine-status /usr/local/bin/machine-release
sudo ln -s /usr/local/bin/machine-status /usr/local/bin/machine-reserve
sudo ln -s /usr/local/bin/machine-status /usr/local/bin/machine-report
machine-release
