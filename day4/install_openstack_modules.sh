#!/usr/bin/env bash
# Quick installation script for OpenStack modules and dependencies
# This is a convenience wrapper that installs everything needed for day4 OpenStack labs

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() {
  printf '[install] %s\n' "$*"
}

abort() {
  printf '[install][error] %s\n' "$*" >&2
  exit 1
}

PYTHON_BIN=${PYTHON:-python3}
command -v "$PYTHON_BIN" >/dev/null 2>&1 || abort "Python 3 not found. Install Python before running this script."

log "Installing Python OpenStack packages..."
"$PYTHON_BIN" -m pip install --upgrade pip
"$PYTHON_BIN" -m pip install --upgrade openstacksdk python-openstackclient

log "Installing Ansible OpenStack collection..."
command -v ansible-galaxy >/dev/null 2>&1 || abort "ansible-galaxy not found. Install Ansible before running this script."
ansible-galaxy collection install --upgrade openstack.cloud

log "Verifying installation..."
if "$PYTHON_BIN" -c "import openstack" 2>/dev/null; then
  SDK_VERSION=$("$PYTHON_BIN" -c "import openstack; print(openstack.version.__version__)")
  log "✓ OpenStack SDK installed (version ${SDK_VERSION})"
else
  abort "OpenStack SDK verification failed"
fi

if ansible-galaxy collection list | grep -q openstack.cloud; then
  log "✓ Ansible openstack.cloud collection installed"
else
  abort "Ansible collection installation failed"
fi

log "All OpenStack modules are installed and ready."
log "Next steps:"
log "  1. Configure clouds.yaml with your OpenStack credentials"
log "  2. Run a test: ansible-playbook Openstack/ansible_openstack_lab-fullest/scenario1_basic_vm.yml"
