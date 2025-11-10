#!/usr/bin/env bash
# Installs the Python packages and Ansible collections required by the
# OpenStack scenarios and playbooks in this repository.

set -euo pipefail

PYTHON_BIN=${PYTHON:-python3}
PIP_FLAGS=${PIP_FLAGS:-}
ANSIBLE_COLLECTION_FLAGS=${ANSIBLE_COLLECTION_FLAGS:-}

if [[ -n "${PIP_FLAGS}" ]]; then
  read -r -a PIP_FLAGS_ARR <<< "${PIP_FLAGS}"
else
  PIP_FLAGS_ARR=()
fi

if [[ -n "${ANSIBLE_COLLECTION_FLAGS}" ]]; then
  read -r -a ANSIBLE_COLLECTION_FLAGS_ARR <<< "${ANSIBLE_COLLECTION_FLAGS}"
else
  ANSIBLE_COLLECTION_FLAGS_ARR=()
fi

log() {
  printf '[install-openstack] %s\n' "$*"
}

abort() {
  printf '[install-openstack][error] %s\n' "$*" >&2
  exit 1
}

require_command() {
  local cmd=$1
  command -v "$cmd" >/dev/null 2>&1 || abort "Missing required command: $cmd"
}

log "Using Python interpreter: ${PYTHON_BIN}"
require_command "$PYTHON_BIN"

PIP_CMD=("$PYTHON_BIN" -m pip)
log "Using pip command: ${PIP_CMD[*]} ${PIP_FLAGS}"
if ! "${PIP_CMD[@]}" --version >/dev/null 2>&1; then
  abort "pip is not available for ${PYTHON_BIN}. Install pip before running this script."
fi

PYTHON_PACKAGES=(
  openstacksdk
  python-openstackclient
)

for package in "${PYTHON_PACKAGES[@]}"; do
  log "Installing Python package: ${package}"
  "${PIP_CMD[@]}" install "${PIP_FLAGS_ARR[@]}" --upgrade "${package}"
done

require_command ansible-galaxy

ANSIBLE_COLLECTIONS=(
  openstack.cloud
)

for collection in "${ANSIBLE_COLLECTIONS[@]}"; do
  log "Installing Ansible collection: ${collection}"
  ansible-galaxy collection install "${ANSIBLE_COLLECTION_FLAGS_ARR[@]}" --upgrade "${collection}"
done

log "All OpenStack dependencies are installed."
