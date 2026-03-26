#!/bin/bash
sudo echo "Installing script, template and creating symlinks in /usr/local directory"
TARGET_SCRIPT="/usr/local/bin/machine-status"
TARGET_MSG="/usr/local/etc/machine-status.msg"
STATUS_TEMPLATE="/usr/local/etc/machine-status.template"

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

sudo cp ./machine-status ${TARGET_SCRIPT}
sudo chmod 555 ${TARGET_SCRIPT}

if [ ! -L /usr/local/bin/machine-reserve ]; then
  sudo ln -s ${TARGET_SCRIPT} /usr/local/bin/machine-reserve
fi

if [ ! -L /usr/local/bin/machine-release ]; then
  sudo ln -s ${TARGET_SCRIPT} /usr/local/bin/machine-release
fi

if [ ! -L /usr/local/bin/machine-report ]; then
  sudo ln -s ${TARGET_SCRIPT} /usr/local/bin/machine-report
fi

sudo cp ./machine-status.template ${STATUS_TEMPLATE}
sudo touch ${TARGET_MSG}
if [ -f "${TARGET_MSG}" ] && [ ! -s "${TARGET_MSG}" ]; then
  # File exists and is empty
  machine-release
elif [ ! -e "${TARGET_MSG}" ]; then
  # File does not exists
  machine-release
else
  # File exists and is not empty, show content
  machine-status
fi
sudo chmod 666 ${TARGET_MSG}

sudo rm /etc/profile.d/check-machine-status.sh
sudo ln -s ${TARGET_SCRIPT}  /etc/profile.d/check-machine-status.sh

