#!/bin/bash
sudo echo "Installing script, template and creating symlinks in /usr/local directory"
INSTALL_TOPDIR="/usr/local"
INSTALL_BIN_DIR="${INSTALL_TOPDIR}/bin"
TARGET_SCRIPT="${INSTALL_BIN_DIR}/machine-status"
TARGET_MSG="${INSTALL_TOPDIR}/etc/machine-status.msg"
STATUS_TEMPLATE="${INSTALL_TOPDIR}/etc/machine-status.template"

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

sudo cp ./config                ${INSTALL_TOPDIR}/etc/machines.config
sudo cp ./add_machine           ${INSTALL_BIN_DIR}
sudo cp ./list_machines         ${INSTALL_BIN_DIR}
sudo cp ./show_machine          ${INSTALL_BIN_DIR}
sudo cp ./delete_machine        ${INSTALL_BIN_DIR}
sudo cp ./update_machine        ${INSTALL_BIN_DIR}
sudo cp ./update_machine_status ${INSTALL_BIN_DIR}
sudo cp ./machine-status ${TARGET_SCRIPT}
sudo chmod 555 ${TARGET_SCRIPT}
sudo chmod 555 ${INSTALL_BIN_DIR}/add_machine
sudo chmod 555 ${INSTALL_BIN_DIR}/list_machines
sudo chmod 555 ${INSTALL_BIN_DIR}/show_machine
sudo chmod 555 ${INSTALL_BIN_DIR}/delete_machine
sudo chmod 555 ${INSTALL_BIN_DIR}/update_machine
sudo chmod 555 ${INSTALL_BIN_DIR}/update_machine_status

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
sudo chmod 666 ${TARGET_MSG}
if [ -s "${TARGET_MSG}" ]; then
  # File exists and has content
  machine-status
else
  # File exists and is empty or doesn't exists
  machine-release
fi

if [ -f /etc/profile.d/check-machine-status.sh ]; then
  sudo rm /etc/profile.d/check-machine-status.sh
fi
sudo ln -s ${TARGET_SCRIPT}  /etc/profile.d/check-machine-status.sh

