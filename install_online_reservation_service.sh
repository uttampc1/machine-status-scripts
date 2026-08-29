#!/usr/bin/env bash
#set -euo pipefail

install_online_reservation_service() {
  REPO_URL="https://github.com/uttampc1/online-reserve-service.git"
  APP_NAME="machine-online-reservation"
  INSTALL_DIR="/opt/${APP_NAME}"
  VENV_DIR="${INSTALL_DIR}/venv"
  SERVICE_NAME="machine-online-reservation"
  APP_USER="${SUDO_USER:-$(whoami)}"
  APP_GROUP="$(id -gn "$APP_USER")"
  APP_FILE="app.py"

  log() {
    echo "[INFO] $*"
  }

  fail() {
    echo "[ERROR] $*" >&2
    exit 1
  }

  require_sudo() {
    if ! command -v sudo >/dev/null 2>&1; then
      fail "sudo is required"
    fi
  }

  install_packages() {
    log "Installing required OS packages..."
    sudo apt-get update
    sudo apt-get install -y git python3 python3-venv python3-pip
  }

  clone_or_update_repo() {
    if [ ! -d "${INSTALL_DIR}" ]; then
      log "Cloning repo into ${INSTALL_DIR}..."
      sudo rm -rf "${INSTALL_DIR}"
      sudo git clone "${REPO_URL}" "${INSTALL_DIR}"
    else
      log "Repo already exists, pulling latest changes..."
      sudo git -C "${INSTALL_DIR}" pull
    fi

    sudo chown -R "${APP_USER}:${APP_GROUP}" "${INSTALL_DIR}"
  }

  create_venv() {
    log "Creating/recreating virtual environment..."
    rm -rf "${VENV_DIR}"
    python3 -m venv "${VENV_DIR}"
  }

  install_requirements() {
    log "Installing Python requirements into venv..."
    "${VENV_DIR}/bin/python" -m pip install --upgrade pip setuptools wheel

    if [ -f "${INSTALL_DIR}/requirements.txt" ]; then
      "${VENV_DIR}/bin/python" -m pip install -r "${INSTALL_DIR}/requirements.txt"
    else
      log "requirements.txt not found, installing Flask manually"
      "${VENV_DIR}/bin/python" -m pip install flask
    fi

    log "Installed packages:"
    "${VENV_DIR}/bin/python" -m pip list
  }

  create_systemd_service() {
    log "Creating systemd service..."
    sudo tee "/etc/systemd/system/${SERVICE_NAME}.service" >/dev/null <<EOF
[Unit]
Description=Online Reservation Service
After=network.target

[Service]
Type=simple
User=${APP_USER}
Group=${APP_GROUP}
WorkingDirectory=${INSTALL_DIR}
Environment="PATH=${VENV_DIR}/bin:/usr/local/bin:/usr/bin:/bin"
Environment="PYTHONUNBUFFERED=1"
ExecStart=${VENV_DIR}/bin/python -u ${INSTALL_DIR}/${APP_FILE}
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
  }

  enable_and_start_service() {
    log "Reloading systemd..."
    sudo systemctl daemon-reload

    log "Enabling service..."
    sudo systemctl enable "${SERVICE_NAME}"

    log "Restarting service..."
    sudo systemctl restart "${SERVICE_NAME}"

    log "Service status:"
    sudo systemctl --no-pager --full status "${SERVICE_NAME}" || true
  }

  require_sudo
  install_packages
  clone_or_update_repo
  create_venv
  install_requirements
  create_systemd_service
  enable_and_start_service

  log "Installation complete."
  log "Service name: ${SERVICE_NAME}"
  log "Logs: sudo journalctl -u ${SERVICE_NAME} -f"
}

install_online_reservation_service
