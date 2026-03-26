#!/bin/bash
sudo echo "Installing script, template and creating symlinks in /usr/local directory"
TARGET_SCRIPT="/usr/local/bin/machine-status"
MOTD_TEMPLATE="/usr/local/etc/motd.template"

copy_it=0
if [ ! -f ${TARGET_SCRIPT} ]; then
  copy_it=1
else
  x=`diff ./machine-status ${TARGET_SCRIPT}`
  if [ "x${x}" != "x" ]; then
    copy_it=1
  fi
fi

if [ ${copy_it} -eq 1 ]; then
  sudo cp ./machine-status ${TARGET_SCRIPT}
  sudo chmod 555 ${TARGET_SCRIPT}
fi

copy_it=0
if [ ! -f ${MOTD_TEMPLATE} ]; then
  copy_it=1
else
  x=`diff ./motd.template ${MOTD_TEMPLATE}`
  if [ "x${x}" != "x" ]; then
    copy_it=1
  fi
fi

if [ ${copy_it} -eq 1 ]; then
  sudo cp ./motd.template ${MOTD_TEMPLATE}
fi

if [ -f /etc/motd ]; then
  sudo cp /etc/motd /etc/motd.orig
  echo "Saved existing /etc/motd file as /etc/motd.orig"
else
  sudo touch /etc/motd
fi

sudo chmod 666 /etc/motd

if [ ! -L /usr/local/bin/machine-reserve ]; then
  sudo ln -s ${TARGET_SCRIPT} /usr/local/bin/machine-reserve
fi

if [ ! -L /usr/local/bin/machine-release ]; then
  sudo ln -s ${TARGET_SCRIPT} /usr/local/bin/machine-release
fi

if [ ! -L /usr/local/bin/machine-report ]; then
  sudo ln -s ${TARGET_SCRIPT} /usr/local/bin/machine-report
fi

sudo touch /var/log/machine-status.log
sudo chmod 666 /var/log/machine-status.log

machine-status
