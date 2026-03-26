#!/bin/bash
sudo echo "Installing script, template and creating symlinks in /usr/local directory"
TARGET_SCRIPT="/usr/local/bin/machine-status"
MOTD_TEMPLATE="/usr/local/etc/motd.template"

sudo touch /var/log/machine-status.log
sudo chmod 666 /var/log/machine-status.log

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

if [ ! -L /usr/local/bin/machine-reserve ]; then
  sudo ln -s ${TARGET_SCRIPT} /usr/local/bin/machine-reserve
fi

if [ ! -L /usr/local/bin/machine-release ]; then
  sudo ln -s ${TARGET_SCRIPT} /usr/local/bin/machine-release
fi

if [ ! -L /usr/local/bin/machine-report ]; then
  sudo ln -s ${TARGET_SCRIPT} /usr/local/bin/machine-report
fi

if [ ${copy_it} -eq 1 ]; then
  sudo cp ./motd.template ${MOTD_TEMPLATE}
fi

sudo touch /etc/motd
if [ -f "/etc/motd" ] && [ ! -s "/etc/motd" ]; then
	# File exists and is empty
  machine-release
elif [ ! -e "/etc/motd" ]; then
	# File does not exists
  machine-release
else
	# File exists and is not empty, show content
  machine-status
fi
sudo chmod 666 /etc/motd

