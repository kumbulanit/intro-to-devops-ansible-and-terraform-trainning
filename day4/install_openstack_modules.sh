#!/usr/bin/env bash
# Convenience wrapper for the OpenStack lab installer.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="${SCRIPT_DIR}/Openstack/ansible_openstack_lab-fullest"

exec "${LAB_DIR}/quick-install.sh" "$@"
