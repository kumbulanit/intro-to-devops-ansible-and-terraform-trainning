#!/usr/bin/env bash

################################################################################
# Quick Install Script for OpenStack Ansible Dependencies
# Uses a project-local virtual environment so it works cleanly on Ubuntu 22.04+
# and Ubuntu 24.04 without fighting system-managed Python packages.
################################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_BIN=${PYTHON:-python3}
VENV_DIR=${VENV_DIR:-"${SCRIPT_DIR}/.venv"}

require_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "Error: missing required command '$1'" >&2
        exit 1
    fi
}

ensure_venv() {
    if [[ ! -d "${VENV_DIR}" ]]; then
        echo "-> Creating virtual environment at ${VENV_DIR}"
        if ! "${PYTHON_BIN}" -m venv "${VENV_DIR}" >/dev/null 2>&1; then
            echo "Error: unable to create a virtual environment." >&2
            echo "On Ubuntu install the venv package first: sudo apt-get install -y python3-venv" >&2
            exit 1
        fi
    fi
}

echo "=================================="
echo "Quick OpenStack Ansible Setup"
echo "=================================="
echo ""

require_cmd "${PYTHON_BIN}"
ensure_venv

PYTHON="${VENV_DIR}/bin/python"
PIP="${VENV_DIR}/bin/pip"
ANSIBLE_GALAXY="${VENV_DIR}/bin/ansible-galaxy"

echo "-> Upgrading pip inside the virtual environment..."
"${PYTHON}" -m pip install --quiet --upgrade pip

echo "-> Installing Python packages from requirements.txt..."
"${PIP}" install --quiet -r "${SCRIPT_DIR}/requirements.txt"

echo "-> Installing Ansible collections..."
"${ANSIBLE_GALAXY}" collection install -r "${SCRIPT_DIR}/requirements.yml" --force >/dev/null 2>&1

echo "-> Verifying installation..."
if "${PYTHON}" -c "import openstack" 2>/dev/null; then
    VERSION=$("${PYTHON}" -c "import openstack; print(openstack.version.__version__)")
    echo "  OpenStack SDK installed (v${VERSION})"
else
    echo "Error: OpenStack SDK installation failed" >&2
    exit 1
fi

if "${ANSIBLE_GALAXY}" collection list | grep -q openstack.cloud; then
    echo "  Ansible OpenStack collection installed"
else
    echo "Error: Ansible collection installation failed" >&2
    exit 1
fi

echo ""
echo "Installation complete."
echo ""
echo "Use the environment:"
echo "  source \"${VENV_DIR}/bin/activate\""
echo ""
echo "Next steps:"
echo "  1. Update ${SCRIPT_DIR}/clouds.yaml or ~/.config/openstack/clouds.yaml"
echo "  2. Test: ${VENV_DIR}/bin/ansible-playbook ${SCRIPT_DIR}/test-openstack.yml"
echo "  3. Run scenarios: ${VENV_DIR}/bin/ansible-playbook ${SCRIPT_DIR}/scenario1_basic_vm.yml"
