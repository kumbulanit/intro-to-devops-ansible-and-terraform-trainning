#!/usr/bin/env bash
set -euo pipefail

# Deploy three independent DevStack-based OpenStack clouds on a single Ubuntu host using LXD containers.
# Each cloud runs in its own container with its own NAT network, static management IP, and host port proxies
# for Horizon (TCP/80) and Keystone API (TCP/5000). Horizon/Keystone are reachable on the host via unique ports.

if [[ ${EUID} -ne 0 ]]; then
  echo "[ERROR] Please run this script as root (sudo)." >&2
  exit 1
fi

for cmd in lxc git; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "[ERROR] Missing dependency: $cmd" >&2
    exit 1
  fi
done

STACK_BRANCH=${STACK_BRANCH:-"2024.1"}
ADMIN_PASSWORD=${ADMIN_PASSWORD:-"SuperStackPass!"}
AUTO_RUN_STACK=${AUTO_RUN_STACK:-"false"}
FORCE_REDEPLOY=${FORCE_REDEPLOY:-"false"}

CLOUD_MATRIX=(
  "cloud-a:ds-net-a:10.201.1.1/24:10.201.1.10:10.201.1.50-10.201.1.150:18080:15000:RegionOneA:192.168.10.0/24:172.31.10.0/24"
  "cloud-b:ds-net-b:10.202.1.1/24:10.202.1.10:10.202.1.50-10.202.1.150:28080:25000:RegionOneB:192.168.20.0/24:172.31.20.0/24"
  "cloud-c:ds-net-c:10.203.1.1/24:10.203.1.10:10.203.1.50-10.203.1.150:38080:35000:RegionOneC:192.168.30.0/24:172.31.30.0/24"
)

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

ensure_container() {
  local instance=$1
  local network=$2
  local ip=$3

  if lxc info "$instance" >/dev/null 2>&1; then
    if [[ "$FORCE_REDEPLOY" == "true" ]]; then
      echo "[WARN] Redeploy requested, deleting existing container $instance"
      lxc stop "$instance" --force || true
      lxc delete "$instance"
    else
      echo "[INFO] Container $instance already exists"
      return 1
    fi
  fi

  echo "[INFO] Creating container $instance"
  lxc init images:ubuntu/22.04 "$instance"
  if lxc config device show "$instance" | grep -q "eth0"; then
    lxc config device remove "$instance" eth0
  fi
  lxc network attach "$network" "$instance" eth0
  lxc config device set "$instance" eth0 ipv4.address "$ip"
  lxc start "$instance"
  return 0
}

wait_for_container() {
  local instance=$1
  echo "[INFO] Waiting for $instance to reach RUNNING state"
  for _ in {1..30}; do
    local state
    state=$(lxc info "$instance" | awk '/Status:/ {print $2}')
    if [[ "$state" == "Running" ]]; then
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
  lxc exec "$instance" -- bash -c '
    set -euo pipefail
    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get install -y git sudo python3 python3-pip build-essential lsb-release
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
  echo "[INFO] Ensuring DevStack repo present in $instance (branch $branch)"
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

  echo "[INFO] Writing local.conf for $instance"
  lxc exec "$instance" -- sudo -H -u stack bash -s -- "$admin_pw" "$host_ip" "$region" "$fixed_range" "$floating_range" <<'EOF'
set -euo pipefail
admin_pw="$1"
host_ip="$2"
region="$3"
fixed_range="$4"
floating_range="$5"
cd /opt/stack/devstack
cat > local.conf <<LOCAL
[[local|localrc]]
ADMIN_PASSWORD=$admin_pw
DATABASE_PASSWORD=$admin_pw
RABBIT_PASSWORD=$admin_pw
SERVICE_PASSWORD=$admin_pw
HOST_IP=$host_ip
SERVICE_HOST=$host_ip
MULTI_HOST=1
LOGFILE=/opt/stack/logs/stack.sh.log
ENABLED_SERVICES+=,q-svc,q-agt,q-dhcp,q-l3,q-meta
IP_VERSION=4
FLOATING_RANGE=$floating_range
FIXED_RANGE=$fixed_range
Q_FLOATING_ALLOCATION_POOL=start=${floating_range%0/24}100,end=${floating_range%0/24}199
KEYSTONE_REGION_NAME=$region
VIRT_DRIVER=libvirt
LIBVIRT_TYPE=qemu
enable_plugin heat https://opendev.org/openstack/heat
LOCAL
EOF
EOF
}

ensure_proxy_device() {
  local instance=$1
  local device=$2
  local listen=$3
  local connect=$4

  if lxc config device show "$instance" | grep -q "^$device:"; then
    echo "[INFO] Proxy device $device already set on $instance"
    return
  fi

  echo "[INFO] Adding proxy device $device (listen $listen -> connect $connect)"
  lxc config device add "$instance" "$device" proxy listen="$listen" connect="$connect"
}

maybe_run_stack() {
  local instance=$1
  if [[ "$AUTO_RUN_STACK" == "true" ]]; then
    echo "[INFO] Running stack.sh inside $instance (this will take a while)"
    lxc exec "$instance" -- sudo -H -u stack bash -c 'set -euo pipefail; cd /opt/stack/devstack && ./stack.sh'
  else
    cat <<EON
[INFO] Manual step required for $instance:
  lxc exec $instance -- sudo -H -u stack bash -c 'cd /opt/stack/devstack && ./stack.sh'
EON
  fi
}

summaries=()

for entry in "${CLOUD_MATRIX[@]}"; do
  IFS=":" read -r instance network cidr ip dhcp_range horizon_port keystone_port region fixed_range floating_range <<<"$entry"

  ensure_network "$network" "$cidr" "$dhcp_range"
  created=0
  if ensure_container "$instance" "$network" "$ip"; then
    created=1
  fi
  wait_for_container "$instance"
  bootstrap_container "$instance"
  clone_devstack "$instance" "$STACK_BRANCH"
  write_local_conf "$instance" "$ADMIN_PASSWORD" "$ip" "$region" "$fixed_range" "$floating_range"
  ensure_proxy_device "$instance" "horizon" "tcp:0.0.0.0:$horizon_port" "tcp:$ip:80"
  ensure_proxy_device "$instance" "keystone" "tcp:0.0.0.0:$keystone_port" "tcp:$ip:5000"
  maybe_run_stack "$instance"
  summaries+=("$instance:$ip:$horizon_port:$keystone_port:$region:$created")
  echo "[INFO] Completed configuration for $instance"
  echo
done

echo "==================== Deployment Summary ===================="
for summary in "${summaries[@]}"; do
  IFS=":" read -r name ip hport kport region created <<<"$summary"
  status="ready"
  if [[ "$created" -eq 1 ]]; then
    status="created"
  fi
  printf "%-8s | mgmt IP: %-15s | Horizon http://<host>:%-5s | Keystone http://<host>:%-5s | Region: %-12s | %s\n" \
    "$name" "$ip" "$hport" "$kport" "$region" "$status"
done
echo "============================================================="

echo "Next steps:" \
"
 1. Run stack.sh inside each container if AUTO_RUN_STACK was not enabled." \
"
 2. Update your clouds.yaml with the host ports printed above." \
"
 3. Use horizon via the mapped host ports once stack.sh completes." \
"
 4. When finished, stop containers with: lxc stop cloud-a cloud-b cloud-c" \
"
 5. Remove everything: lxc delete cloud-a cloud-b cloud-c && lxc network delete ds-net-a ds-net-b ds-net-c"
