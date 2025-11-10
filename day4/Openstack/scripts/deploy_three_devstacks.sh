#!/usr/bin/env bash

# Deploy up to three isolated DevStack-based OpenStack labs on a single Ubuntu host using LXD containers.
# Each lab gets its own container, IP address, and unique service ports.
#
# Usage:
#   chmod +x deploy_three_devstacks.sh
#   ./deploy_three_devstacks.sh
#
# Tuning via environment variables:
#   CLOUD_COUNT        Number of DevStack clouds to provision (default: 3, max tested: 3)
#   BASE_NAME          Container name prefix (default: openstack-lab)
#   RELEASE            DevStack branch to clone (default: stable/2024.2)
#   RUN_STACK          Set to 1 to automatically execute stack.sh inside each container (default: 0)
#   ADMIN_PASSWORD     Keystone admin password (default: stackadmin)
#   SERVICE_PASSWORD   Keystone service user password (default: stackservice)
#   DATABASE_PASSWORD  MariaDB root password (default: stackdb)
#   RABBIT_PASSWORD    RabbitMQ password (default: stackrabbit)
#   PORT_STEP          Increment added to service ports for each additional cloud (default: 20)
#   KEYSTONE_BASE_PORT Starting port for Keystone API (default: 5000)
#   HORIZON_BASE_PORT  Starting port for Horizon dashboard (default: 8080)
#
# After the script completes, follow the README in the same directory for validation and dashboard access.

set -euo pipefail

CLOUD_COUNT=${CLOUD_COUNT:-3}
BASE_NAME=${BASE_NAME:-openstack-lab}
RELEASE=${RELEASE:-stable/2024.2}
RUN_STACK=${RUN_STACK:-0}
ADMIN_PASSWORD=${ADMIN_PASSWORD:-stackadmin}
SERVICE_PASSWORD=${SERVICE_PASSWORD:-stackservice}
DATABASE_PASSWORD=${DATABASE_PASSWORD:-stackdb}
RABBIT_PASSWORD=${RABBIT_PASSWORD:-stackrabbit}
PORT_STEP=${PORT_STEP:-20}
KEYSTONE_BASE_PORT=${KEYSTONE_BASE_PORT:-5000}
HORIZON_BASE_PORT=${HORIZON_BASE_PORT:-8080}

if [[ ${CLOUD_COUNT} -lt 1 || ${CLOUD_COUNT} -gt 3 ]]; then
  echo "[ERROR] CLOUD_COUNT must be between 1 and 3." >&2
  exit 1
fi

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "[ERROR] Missing required command: $1" >&2
    exit 1
  fi
}

ensure_lxd_ready() {
  if ! systemctl is-active --quiet snap.lxd.daemon; then
    echo "[INFO] Installing LXD snap..."
    sudo snap install lxd || true
    echo "[INFO] Waiting for LXD to settle..."
    sleep 5
  fi

  if ! lxd waitready >/dev/null 2>&1; then
    echo "[INFO] Initializing LXD with defaults..."
    sudo lxd init --auto
  fi

  # Ensure the current user can talk to LXD
  if ! getent group lxd | grep -qw "${USER}"; then
    echo "[INFO] Adding ${USER} to lxd group. Logout/login required for immediate effect."
    sudo usermod -aG lxd "${USER}"
  fi
}

launch_container() {
  local name=$1
  if lxc info "${name}" >/dev/null 2>&1; then
    echo "[INFO] Container ${name} already exists. Skipping launch."
    return
  fi

  echo "[INFO] Launching container ${name} (ubuntu:24.04)..."
  lxc launch images:ubuntu/24.04 "${name}"

  echo "[INFO] Enabling nesting inside ${name} for DevStack requirements..."
  lxc config set "${name}" security.nesting true

  echo "[INFO] Waiting for cloud-init to complete in ${name}..."
  lxc exec "${name}" -- cloud-init status --wait
}

container_ip() {
  local name=$1
  lxc list "${name}" -c4 --format csv | awk '{print $1}'
}

copy_devstack_scripts() {
  local name=$1
  local keystone_port=$2
  local horizon_port=$3

  local ip
  ip=$(container_ip "${name}")
  if [[ -z "${ip}" ]]; then
    echo "[ERROR] Unable to determine IP address for ${name}." >&2
    exit 1
  fi

  echo "[INFO] Preparing DevStack inside ${name} (IP: ${ip})..."
  lxc exec "${name}" -- bash -lc "set -euo pipefail; \n    sudo apt-get update -y && sudo apt-get install -y git sudo net-tools python3-pip \n    && id stack >/dev/null 2>&1 || sudo useradd -s /bin/bash -d /opt/stack -m stack \n    && echo 'stack ALL=(ALL) NOPASSWD: ALL' | sudo tee /etc/sudoers.d/stack >/dev/null \n    && sudo -u stack bash -lc 'if [ ! -d devstack ]; then git clone https://opendev.org/openstack/devstack -b ${RELEASE}; fi'"

  echo "[INFO] Writing local.conf for ${name}..."
  lxc exec "${name}" -- bash -lc "set -euo pipefail; \n    sudo -u stack bash -lc 'cat > devstack/local.conf <<\"EOF\"\n[[local|localrc]]\nHOST_IP=${ip}\nSERVICE_HOST=${ip}\nSERVICE_PROTOCOL=http\nADMIN_PASSWORD=${ADMIN_PASSWORD}\nDATABASE_PASSWORD=${DATABASE_PASSWORD}\nRABBIT_PASSWORD=${RABBIT_PASSWORD}\nSERVICE_PASSWORD=${SERVICE_PASSWORD}\nLOGFILE=\$DEST/logs/stack.sh.log\nLOGDIR=\$DEST/logs\nENABLE_IDENTITY_V2=False\nKEYSTONE_SERVICE_PORT=${keystone_port}\nKEYSTONE_AUTH_PORT=${keystone_port}\nKEYSTONE_PUBLIC_ENDPOINT=http://${ip}:${keystone_port}/v3\nKEYSTONE_ADMIN_ENDPOINT=http://${ip}:${keystone_port}/v3\nHORIZON_PORT=${horizon_port}\n\n[[post-config|\$KEYSTONE_CONF]]\n[DEFAULT]\npublic_port=${keystone_port}\nadmin_port=${keystone_port}\n\n[[post-config|\$HORIZON_CONF]]\n[uwsgi]\nhttp=${ip}:${horizon_port}\n\nEOF'"

  echo "[INFO] local.conf created for ${name} with Keystone port ${keystone_port} and Horizon port ${horizon_port}."

  if [[ "${RUN_STACK}" == "1" ]]; then
    echo "[INFO] Executing stack.sh inside ${name}. This can take 20-40 minutes."
    lxc exec "${name}" -- bash -lc "set -euo pipefail; sudo -u stack bash -lc 'cd devstack && ./stack.sh'"
  else
    echo "[INFO] Skipped stack.sh execution for ${name}. Run manually with:"
    echo "       lxc exec ${name} -- sudo -u stack bash -lc 'cd devstack && ./stack.sh'"
  fi
}

summarize_access() {
  printf '\n===== Deployment Summary =====\n'
  for idx in $(seq 1 "${CLOUD_COUNT}"); do
    local name="${BASE_NAME}-${idx}"
    local ip
    ip=$(container_ip "${name}")
    local keystone_port=$(( KEYSTONE_BASE_PORT + (idx - 1) * PORT_STEP ))
    local horizon_port=$(( HORIZON_BASE_PORT + (idx - 1) * PORT_STEP ))

    printf '\nCloud %d: %s\n' "${idx}" "${name}"
    printf '  Container IP: %s\n' "${ip:-pending}" 
    printf '  Keystone URL: http://%s:%d/v3\n' "${ip:-pending}" "${keystone_port}"
    printf '  Horizon URL:  http://%s:%d/\n' "${ip:-pending}" "${horizon_port}"
    printf '  Credentials:  admin / %s\n' "${ADMIN_PASSWORD}"
  done
  printf '\nNOTE: If RUN_STACK=0, run stack.sh inside each container before using the cloud.\n'
}

main() {
  require_cmd lxc
  require_cmd git
  require_cmd sudo

  ensure_lxd_ready

  for idx in $(seq 1 "${CLOUD_COUNT}"); do
    local name="${BASE_NAME}-${idx}"
    local keystone_port=$(( KEYSTONE_BASE_PORT + (idx - 1) * PORT_STEP ))
    local horizon_port=$(( HORIZON_BASE_PORT + (idx - 1) * PORT_STEP ))

    launch_container "${name}"
    copy_devstack_scripts "${name}" "${keystone_port}" "${horizon_port}"
  done

  summarize_access
}

main "$@"
