#!/bin/bash
sudo echo "Installing script, template and creating symlinks in /usr/local directory"

INSTALL_TOPDIR="/usr/local"
INSTALL_BIN_DIR="${INSTALL_TOPDIR}/bin"
INSTALL_ETC_DIR="${INSTALL_TOPDIR}/etc"

TARGET_SCRIPT="${INSTALL_BIN_DIR}/machine-status"
TARGET_MSG="${INSTALL_TOPDIR}/etc/machine-status.msg"
STATUS_TEMPLATE="${INSTALL_TOPDIR}/etc/machine-status.template"

MACHINE_STATUS="${INSTALL_BIN_DIR}/machine-status"
ADD_MACHINE="${INSTALL_BIN_DIR}/add_machine"
LIST_MACHINES="${INSTALL_BIN_DIR}/list_machines"
SHOW_MACHINE="${INSTALL_BIN_DIR}/show_machine"
DELETE_MACHINE="${INSTALL_BIN_DIR}/delete_machine"
UPDATE_MACHINE="${INSTALL_BIN_DIR}/update_machine"
UPDATE_MACHINE_STATUS="${INSTALL_BIN_DIR}/update_machine_status"
LOG_SCRIPT="${INSTALL_BIN_DIR}/log_usage.sh"
ANALYZE_SCRIPT="${INSTALL_BIN_DIR}/analyze.sh"

CRON_DST="/etc/cron.d/machine-usage-monitor"

sudo mkdir -p "${INSTALL_BIN_DIR}" "${INSTALL_ETC_DIR}"

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

sudo cp ./machines.config            ${INSTALL_ETC_DIR}/etc/machines.config
sudo cp ./machine-status             ${MACHINE_STATUS}
sudo cp ./add_machine                ${ADD_MACHINE}
sudo cp ./list_machines              ${LIST_MACHINES}
sudo cp ./show_machine               ${SHOW_MACHINE}
sudo cp ./delete_machine             ${DELETE_MACHINE}
sudo cp ./update_machine             ${UPDATE_MACHINE}
sudo cp ./update_machine_status      ${UPDATE_MACHINE_STATUS}
sudo cp ./log_usage.sh               ${LOG_SCRIPT}
sudo cp ./analyze.sh                 ${ANALYZE_SCRIPT}
sudo cp ./machine-usage-monitor.cron ${CRON_DST}

sudo chmod 555 ${MACHINE_STATUS}
sudo chmod 555 ${ADD_MACHINE}
sudo chmod 555 ${LIST_MACHINES}
sudo chmod 555 ${SHOW_MACHINE}
sudo chmod 555 ${DELETE_MACHINE}
sudo chmod 555 ${UPDATE_MACHINE}
sudo chmod 555 ${UPDATE_MACHINE_STATUS}
sudo chmod 555 ${LOG_SCRIPT}
sudo chmod 555 ${ANALYZE_SCRIPT}
sudo chmod 644 ${CRON_DST}

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

# Install cron jobs to run log_usage.sh and analyze.sh: TODO

# Install cron jobs:
# - collect usage every 15 minutes
# - analyze once per day at midnight
echo "Installed:"
echo "  config   -> ${INSTALL_ETC_DIR}/machines.config"
echo "  scripts  -> "
echo "     ${MACHINE_STATUS}"
echo "     ${INSTALL_BIN_DIR}/machine-reserve"
echo "     ${INSTALL_BIN_DIR}/machine-release"
echo "     ${INSTALL_BIN_DIR}/machine-report"
echo "     ${ADD_MACHINE}"
echo "     ${LIST_MACHINES}"
echo "     ${SHOW_MACHINE}"
echo "     ${DELETE_MACHINE}"
echo "     ${UPDATE_MACHINE}"
echo "     ${UPDATE_MACHINE_STATUS}"
echo "     ${LOG_SCRIPT}"
echo "     ${ANALYZE_SCRIPT}"
echo "  cron     -> ${CRON_DST}"
echo
echo "Cron schedule:"
echo "  log_usage.sh : log usage every 15 minutes"
echo "  analyze.sh   : analyze usage every 24 hours at 00:00"
