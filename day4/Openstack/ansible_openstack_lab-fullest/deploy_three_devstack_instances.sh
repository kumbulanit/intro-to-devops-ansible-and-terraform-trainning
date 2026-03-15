#!/usr/bin/env bash
set -euo pipefail

# Deploy three independent DevStack-based OpenStack clouds on a single Ubuntu
# host using LXD containers. Each cloud gets a dedicated network, static
# management IP, and host-side proxy ports for Horizon and Keystone.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_BRANCH=${STACK_BRANCH:-"stable/2024.2"}
ADMIN_PASSWORD=${ADMIN_PASSWORD:-"SuperStackPass!"}
AUTO_RUN_STACK=${AUTO_RUN_STACK:-"false"}
FORCE_REDEPLOY=${FORCE_REDEPLOY:-"false"}
UBUNTU_IMAGE=${UBUNTU_IMAGE:-"images:ubuntu/24.04"}
HOST_BIND_ADDRESS=${HOST_BIND_ADDRESS:-"0.0.0.0"}
CLOUDS_OUTPUT_FILE=${CLOUDS_OUTPUT_FILE:-"${SCRIPT_DIR}/generated-clouds.yaml"}

CLOUD_MATRIX=(
  "cloud-a:ds-net-a:10.201.1.1/24:10.201.1.10:10.201.1.50-10.201.1.150:18080:15000:RegionOneA:192.168.10.0/24:172.31.10.0/24"
  "cloud-b:ds-net-b:10.202.1.1/24:10.202.1.10:10.202.1.50-10.202.1.150:28080:25000:RegionOneB:192.168.20.0/24:172.31.20.0/24"
  "cloud-c:ds-net-c:10.203.1.1/24:10.203.1.10:10.203.1.50-10.203.1.150:38080:35000:RegionOneC:192.168.30.0/24:172.31.30.0/24"
)

HOST_PUBLIC_IP=${HOST_PUBLIC_IP:-}
summaries=()

require_root() {
  if [[ ${EUID} -ne 0 ]]; then
    echo "[ERROR] Please run this script as root (sudo)." >&2
    exit 1
  fi
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "[ERROR] Missing dependency: $1" >&2
    exit 1
  fi
}

detect_host_ip() {
  local detected=""

  if command -v ip >/dev/null 2>&1; then
    detected=$(ip route get 1.1.1.1 2>/dev/null | awk '/src/ {for (i = 1; i <= NF; i++) if ($i == "src") {print $(i + 1); exit}}')
  fi

  if [[ -z "${detected}" ]] && command -v hostname >/dev/null 2>&1; then
    detected=$(hostname -I 2>/dev/null | awk '{print $1}')
  fi

  if [[ -z "${detected}" ]]; then
    detected="127.0.0.1"
  fi

  printf '%s' "${detected}"
}

ensure_lxd_ready() {
  if ! command -v lxc >/dev/null 2>&1; then
    require_cmd snap
    echo "[INFO] Installing LXD via snap"
    snap install lxd
  fi

  if ! lxd waitready >/dev/null 2>&1; then
    echo "[INFO] Initializing LXD with default settings"
    lxd init --auto
  fi
}

ensure_network() {
  local name=$1
  local cidr=$2
  local dhcp_range=$3

  if lxc network show "$name" >/dev/null 2>&1; then
    echo "[INFO] LXD network $name already present"
    return
  fi

  echo "[INFO] Creating LXD network $name ($cidr, DHCP $dhcp_range)"
  lxc network create "$name" \
    ipv4.address="$cidr" \
    ipv4.dhcp.ranges="$dhcp_range" \
    ipv4.nat=true \
    ipv6.address=none
}

configure_container_runtime() {
  local instance=$1

  lxc config set "$instance" security.nesting true
  lxc config set "$instance" security.privileged true

  if [[ -e /dev/kvm ]] && ! lxc config device show "$instance" | grep -q '^kvm:'; then
    lxc config device add "$instance" kvm unix-char source=/dev/kvm path=/dev/kvm || true
  fi
}

ensure_container() {
  local instance=$1
  local network=$2
  local ip_address=$3

  if lxc info "$instance" >/dev/null 2>&1; then
    if [[ "$FORCE_REDEPLOY" == "true" ]]; then
      echo "[WARN] Redeploy requested, deleting existing container $instance"
      lxc delete "$instance" --force
    else
      echo "[INFO] Container $instance already exists"
      return 1
    fi
  fi

  echo "[INFO] Creating container $instance from ${UBUNTU_IMAGE}"
  lxc init "${UBUNTU_IMAGE}" "$instance"
  if lxc config device show "$instance" | grep -q '^eth0:'; then
    lxc config device remove "$instance" eth0
  fi
  lxc network attach "$network" "$instance" eth0
  lxc config device set "$instance" eth0 ipv4.address "$ip_address"
  configure_container_runtime "$instance"
  lxc start "$instance"
  return 0
}

wait_for_container() {
  local instance=$1

  echo "[INFO] Waiting for $instance to boot"
  for _ in {1..30}; do
    if [[ "$(lxc info "$instance" | awk '/Status:/ {print $2}')" == "Running" ]]; then
      if lxc exec "$instance" -- cloud-init status --wait >/dev/null 2>&1; then
        :
      fi
      sleep 5
      return
    fi
    sleep 2
  done

  echo "[ERROR] Container $instance did not start in time" >&2
  exit 1
}

bootstrap_container() {
  local instance=$1
  echo "[INFO] Bootstrapping packages inside $instance"
  lxc exec "$instance" -- bash -lc '
    set -euo pipefail
    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get install -y \
      ca-certificates \
      curl \
      git \
      sudo \
      python3 \
      python3-pip \
      python3-venv \
      build-essential \
      lsb-release \
      net-tools

    if ! id -u stack >/dev/null 2>&1; then
      useradd -s /bin/bash -d /opt/stack -m stack
    fi

    echo "stack ALL=(ALL) NOPASSWD:ALL" >/etc/sudoers.d/90-stack-user
    chmod 0440 /etc/sudoers.d/90-stack-user
  '
}

clone_devstack() {
  local instance=$1
  local branch=$2
  echo "[INFO] Ensuring DevStack repo is present in $instance (branch $branch)"
  lxc exec "$instance" -- sudo -H -u stack bash -s -- "$branch" <<'EOF'
set -euo pipefail
branch="$1"
cd /opt/stack
if [[ ! -d devstack ]]; then
  git clone --depth 1 --branch "$branch" https://opendev.org/openstack/devstack
else
  cd devstack
  current_branch=$(git rev-parse --abbrev-ref HEAD)
  if [[ "$current_branch" != "$branch" ]]; then
    git fetch origin "$branch"
    git checkout "$branch"
    git reset --hard "origin/$branch"
  else
    git pull --ff-only
  fi
fi
EOF
}

write_local_conf() {
  local instance=$1
  local admin_pw=$2
  local host_ip=$3
  local region=$4
  local fixed_range=$5
  local floating_range=$6
  local floating_prefix=${floating_range%0/24}

  echo "[INFO] Writing local.conf for $instance"
  lxc exec "$instance" -- sudo -H -u stack bash -s -- \
    "$admin_pw" "$host_ip" "$region" "$fixed_range" "$floating_range" "$floating_prefix" <<'EOF'
set -euo pipefail
admin_pw="$1"
host_ip="$2"
region="$3"
fixed_range="$4"
floating_range="$5"
floating_prefix="$6"

cd /opt/stack/devstack
cat > local.conf <<LOCAL
[[local|localrc]]
ADMIN_PASSWORD=${admin_pw}
DATABASE_PASSWORD=${admin_pw}
RABBIT_PASSWORD=${admin_pw}
SERVICE_PASSWORD=${admin_pw}
HOST_IP=${host_ip}
SERVICE_HOST=${host_ip}
SERVICE_PROTOCOL=http
MULTI_HOST=1
LOGFILE=/opt/stack/logs/stack.sh.log
LOGDIR=/opt/stack/logs
LOG_COLOR=False
DOWNLOAD_DEFAULT_IMAGES=True
KEYSTONE_REGION_NAME=${region}
IP_VERSION=4
FLOATING_RANGE=${floating_range}
FIXED_RANGE=${fixed_range}
Q_FLOATING_ALLOCATION_POOL=start=${floating_prefix}100,end=${floating_prefix}199
VIRT_DRIVER=qemu
LIBVIRT_TYPE=qemu
ENABLED_SERVICES+=,q-svc,q-agt,q-dhcp,q-l3,q-meta
enable_plugin heat https://opendev.org/openstack/heat
LOCAL
EOF
}

ensure_proxy_device() {
  local instance=$1
  local device=$2
  local listen=$3
  local connect=$4

  if lxc config device show "$instance" | grep -q "^${device}:"; then
    echo "[INFO] Proxy device $device already set on $instance"
    return
  fi

  echo "[INFO] Adding proxy device $device (listen $listen -> connect $connect)"
  lxc config device add "$instance" "$device" proxy listen="$listen" connect="$connect"
}

generate_clouds_yaml() {
  local output_file=$1
  local host_ip=$2

  mkdir -p "$(dirname "$output_file")"
  cat > "$output_file" <<EOF
clouds:
EOF

  for summary in "${summaries[@]}"; do
    IFS=":" read -r name ip hport kport region created <<<"$summary"
    cat >> "$output_file" <<EOF
  ${name}:
    region_name: ${region}
    auth:
      auth_url: http://${host_ip}:${kport}/v3
      username: admin
      password: ${ADMIN_PASSWORD}
      project_name: admin
      user_domain_name: Default
      project_domain_name: Default
    interface: public
    identity_api_version: 3
EOF
  done
}

maybe_run_stack() {
  local instance=$1
  if [[ "$AUTO_RUN_STACK" == "true" ]]; then
    echo "[INFO] Running stack.sh inside $instance (this can take 20-40 minutes)"
    lxc exec "$instance" -- sudo -H -u stack bash -lc 'set -euo pipefail; cd /opt/stack/devstack && ./stack.sh'
  else
    cat <<EOF
[INFO] Manual step required for $instance:
  lxc exec $instance -- sudo -H -u stack bash -lc 'cd /opt/stack/devstack && ./stack.sh'
EOF
  fi
}

print_summary() {
  local host_ip=$1

  echo "==================== Deployment Summary ===================="
  for summary in "${summaries[@]}"; do
    IFS=":" read -r name ip hport kport region created <<<"$summary"
    local status="ready"
    if [[ "$created" -eq 1 ]]; then
      status="created"
    fi
    printf "%-8s | mgmt IP: %-15s | Horizon http://%s:%-5s | Keystone http://%s:%-5s | Region: %-12s | %s\n" \
      "$name" "$ip" "$host_ip" "$hport" "$host_ip" "$kport" "$region" "$status"
  done
  echo "============================================================="
  echo "Generated clouds.yaml snippet: ${CLOUDS_OUTPUT_FILE}"
  cat <<EOF

Next steps:
  1. Run stack.sh inside each container if AUTO_RUN_STACK was not enabled.
  2. Review ${CLOUDS_OUTPUT_FILE} and copy the entries into ~/.config/openstack/clouds.yaml if desired.
  3. Access Horizon using the host IP/ports shown above once stack.sh completes.
  4. Stop containers when idle: lxc stop cloud-a cloud-b cloud-c
  5. Remove everything: lxc delete cloud-a cloud-b cloud-c --force && lxc network delete ds-net-a ds-net-b ds-net-c
EOF
}

main() {
  require_root
  require_cmd git

  if [[ -z "${HOST_PUBLIC_IP}" ]]; then
    HOST_PUBLIC_IP=$(detect_host_ip)
  fi

  ensure_lxd_ready

  for entry in "${CLOUD_MATRIX[@]}"; do
    IFS=":" read -r instance network cidr ip_address dhcp_range horizon_port keystone_port region fixed_range floating_range <<<"$entry"

    ensure_network "$network" "$cidr" "$dhcp_range"
    created=0
    if ensure_container "$instance" "$network" "$ip_address"; then
      created=1
    fi
    wait_for_container "$instance"
    bootstrap_container "$instance"
    clone_devstack "$instance" "$STACK_BRANCH"
    write_local_conf "$instance" "$ADMIN_PASSWORD" "$ip_address" "$region" "$fixed_range" "$floating_range"
    ensure_proxy_device "$instance" "horizon" "tcp:${HOST_BIND_ADDRESS}:${horizon_port}" "tcp:${ip_address}:80"
    ensure_proxy_device "$instance" "keystone" "tcp:${HOST_BIND_ADDRESS}:${keystone_port}" "tcp:${ip_address}:5000"
    maybe_run_stack "$instance"
    summaries+=("$instance:$ip_address:$horizon_port:$keystone_port:$region:$created")
    echo "[INFO] Completed configuration for $instance"
    echo
  done

  generate_clouds_yaml "$CLOUDS_OUTPUT_FILE" "$HOST_PUBLIC_IP"
  print_summary "$HOST_PUBLIC_IP"
}

main "$@"
