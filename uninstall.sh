#!/bin/bash
echo "Uninstalling script, template and removing symlinks in /usr/local directory"

INSTALL_TOPDIR="/usr/local"
INSTALL_BIN_DIR="${INSTALL_TOPDIR}/bin"
INSTALL_LIB_DIR="${INSTALL_TOPDIR}/lib"
INSTALL_ETC_DIR="${INSTALL_TOPDIR}/etc"

TARGET_SCRIPT="${INSTALL_BIN_DIR}/machine-status"
TARGET_MSG="${INSTALL_TOPDIR}/etc/machine-status.msg"
STATUS_TEMPLATE="${INSTALL_TOPDIR}/etc/machine-status.template"

ADD_MACHINE="${INSTALL_BIN_DIR}/add_machine"
LIST_MACHINES="${INSTALL_BIN_DIR}/list_machines"
SHOW_MACHINE="${INSTALL_BIN_DIR}/show_machine"
DELETE_MACHINE="${INSTALL_BIN_DIR}/delete_machine"
UPDATE_MACHINE="${INSTALL_BIN_DIR}/update_machine"
UPDATE_MACHINE_STATUS="${INSTALL_BIN_DIR}/update_machine_status"
EXTEND_RESERVATION_SCRIPT="${INSTALL_BIN_DIR}/extend_reservation"
LOG_SCRIPT="${INSTALL_BIN_DIR}/log_usage.sh"
ANALYZE_SCRIPT="${INSTALL_BIN_DIR}/analyze.sh"
UTILS_SCRIPT="${INSTALL_LIB_DIR}/utils.sh"

INSTALL_SERVICE_DIR="/etc/systemd/system"
MACHINE_USAGE_LOG_SERVICE="${INSTALL_SERVICE_DIR}/machine-usage-log.service"
MACHINE_USAGE_LOG_TIMER="${INSTALL_SERVICE_DIR}/machine-usage-log.timer"
MACHINE_USAGE_ANALYZE_SERVICE="${INSTALL_SERVICE_DIR}/machine-usage-analyze.service"
MACHINE_USAGE_ANALYZE_TIMER="${INSTALL_SERVICE_DIR}/machine-usage-analyze.timer"
ONLINE_RESERVATION_SERVICE="${INSTALL_SERVICE_DIR}/machine-online-reservation.service"

sudo systemctl stop machine-usage-log.timer 2>/dev/null || true
sudo systemctl stop machine-usage-analyze.timer 2>/dev/null || true
sudo systemctl stop machine-online-reservation.service 2>/dev/null || true

sudo systemctl disable machine-usage-log.timer 2>/dev/null || true
sudo systemctl disable machine-usage-log.service 2>/dev/null || true
sudo systemctl disable machine-usage-analyze.timer 2>/dev/null || true
sudo systemctl disable machine-usage-analyze.service 2>/dev/null || true
sudo systemctl disable machine-online-reservation.service 2>/dev/null || true

for f in \
  "${INSTALL_ETC_DIR}/machines.config" \
  "${TARGET_SCRIPT}"                   \
  "${TARGET_MSG}" \
  "${STATUS_TEMPLATE}"  \
  "/usr/local/bin/machine-reserve"  \
  "/usr/local/bin/machine-release"  \
  "/usr/local/bin/machine-report"  \
  "${ADD_MACHINE}"  \
  "${LIST_MACHINES}"  \
  "${SHOW_MACHINE}"  \
  "${DELETE_MACHINE}"  \
  "${UPDATE_MACHINE}"  \
  "${UPDATE_MACHINE_STATUS}"  \
  "${EXTEND_RESERVATION_SCRIPT}"  \
  "${LOG_SCRIPT}"  \
  "${ANALYZE_SCRIPT}"  \
  "${UTILS_SCRIPT}"  \
  "/etc/profile.d/check-machine-status.sh"  \
  "${MACHINE_USAGE_LOG_SERVICE}"  \
  "${MACHINE_USAGE_LOG_TIMER}"  \
  "${MACHINE_USAGE_ANALYZE_SERVICE}"  \
  "${MACHINE_USAGE_ANALYZE_TIMER}"  \
  "${ONLINE_RESERVATION_SERVICE}" \
  "/opt/machine-online-reservation"
do
  if [ -e "${f}" ]; then
    sudo /bin/rm -fr "$f"
  fi
done

sudo systemctl daemon-reload
echo "Uninstall complete."


