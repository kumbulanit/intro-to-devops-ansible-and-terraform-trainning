# Triple DevStack Setup Guide

This guide explains how to spin up **three isolated OpenStack (DevStack) instances** on a single Ubuntu machine. Each cloud runs inside its own LXD container, binding Horizon and Keystone to unique host ports so you can access them side by side.

> **Warning:** Running multiple OpenStack control planes is resource intensive. Plan for **at least 32 GB RAM, 12 vCPUs, and 200 GB free disk** on the host. Expect each stack.sh execution to take 15–30 minutes.

## 1. Prerequisites

- Ubuntu 22.04 (or newer) host with hardware virtualization enabled (for nested KVM).
- Root access (`sudo`).
- LXD 5.x+ installed and initialized.

```bash
sudo snap install lxd
sudo lxd init    # accept defaults or create a dedicated storage pool
```

- Optional but recommended: reboot after enabling KVM modules (`kvm`, `kvm_intel` / `kvm_amd`).

## 2. Script Overview

The `deploy_three_devstack_instances.sh` script performs the following:

1. Creates three dedicated LXD bridge networks (`ds-net-a`, `ds-net-b`, `ds-net-c`).
2. Launches containers `cloud-a`, `cloud-b`, `cloud-c` with static management IPs.
3. Installs DevStack prerequisites, clones DevStack (branch configurable via `$STACK_BRANCH`).
4. Writes customized `local.conf` per container with unique fixed/floating ranges and region names.
5. Adds host port proxies so you can reach:
   - Horizon (dashboard) on ports `18080`, `28080`, `38080`.
   - Keystone public API on ports `15000`, `25000`, `35000`.
6. Optionally runs `stack.sh` automatically if `AUTO_RUN_STACK=true`.

Multiple runs are idempotent; set `FORCE_REDEPLOY=true` to rebuild containers from scratch.

## 3. Usage

From the repository root:

```bash
cd day4/Openstack/ansible_openstack_lab-fullest
chmod +x deploy_three_devstack_instances.sh
sudo STACK_BRANCH=2024.2 ADMIN_PASSWORD='ChangeMe!' ./deploy_three_devstack_instances.sh
```

Environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `STACK_BRANCH` | `2024.1` | DevStack/OpenStack release branch. |
| `ADMIN_PASSWORD` | `SuperStackPass!` | Admin/service passwords injected into each stack. |
| `AUTO_RUN_STACK` | `false` | Set to `true` to run `./stack.sh` automatically (blocking). |
| `FORCE_REDEPLOY` | `false` | Set to `true` to delete/recreate containers and networks. |

### Manual stack.sh run

If `AUTO_RUN_STACK` stays `false`, run inside each container after the script finishes:

```bash
sudo lxc exec cloud-a -- sudo -H -u stack bash -c 'cd /opt/stack/devstack && ./stack.sh'
sudo lxc exec cloud-b -- sudo -H -u stack bash -c 'cd /opt/stack/devstack && ./stack.sh'
sudo lxc exec cloud-c -- sudo -H -u stack bash -c 'cd /opt/stack/devstack && ./stack.sh'
```

You can tail the logs with:

```bash
sudo lxc exec cloud-a -- sudo -H -u stack tail -f /opt/stack/logs/stack.sh.log
```

## 4. Accessing Each Cloud

Assuming the host IP is `192.168.1.10`:

| Cloud | Horizon URL | Keystone URL | Region | Notes |
|-------|-------------|--------------|--------|-------|
| `cloud-a` | `http://192.168.1.10:18080/` | `http://192.168.1.10:15000/v3/` | `RegionOneA` | Uses container IP `10.201.1.10`. |
| `cloud-b` | `http://192.168.1.10:28080/` | `http://192.168.1.10:25000/v3/` | `RegionOneB` | Container IP `10.202.1.10`. |
| `cloud-c` | `http://192.168.1.10:38080/` | `http://192.168.1.10:35000/v3/` | `RegionOneC` | Container IP `10.203.1.10`. |

Credentials (unless overridden):

- Username: `admin`
- Password: value of `$ADMIN_PASSWORD`
- Project: `admin`
- Domain: `Default`

### clouds.yaml example

Add entries to `~/.config/openstack/clouds.yaml`:

```yaml
clouds:
  devstack-a:
    region_name: RegionOneA
    auth:
      auth_url: http://192.168.1.10:15000/v3
      username: admin
      password: SuperStackPass!
      project_name: admin
      user_domain_name: Default
      project_domain_name: Default
  devstack-b:
    region_name: RegionOneB
    auth:
      auth_url: http://192.168.1.10:25000/v3
      username: admin
      password: SuperStackPass!
      project_name: admin
      user_domain_name: Default
      project_domain_name: Default
  devstack-c:
    region_name: RegionOneC
    auth:
      auth_url: http://192.168.1.10:35000/v3
      username: admin
      password: SuperStackPass!
      project_name: admin
      user_domain_name: Default
      project_domain_name: Default
```

Adjust the host IP and password to match your environment.

## 5. Verification Checklist

For each cloud:

1. `openstack --os-cloud devstack-a endpoint list`
2. Launch a test instance:

   ```bash
   openstack --os-cloud devstack-a network list
   openstack --os-cloud devstack-a server create --image cirros-0.6.2 --flavor m1.tiny --network private demo-cirros
   ```

3. Confirm Horizon dashboard loads on the mapped port.

## 6. Maintenance & Cleanup

- Stop control planes when idle to free resources:

  ```bash
  sudo lxc stop cloud-a cloud-b cloud-c
  ```

- Start them again when needed:

  ```bash
  sudo lxc start cloud-a cloud-b cloud-c
  ```

- Remove everything (containers, networks):

  ```bash
  sudo lxc stop cloud-a cloud-b cloud-c
  sudo lxc delete cloud-a cloud-b cloud-c
  sudo lxc network delete ds-net-a
  sudo lxc network delete ds-net-b
  sudo lxc network delete ds-net-c
  ```

## 7. Troubleshooting Tips

- Check container logs: `sudo lxc info cloud-a --show-log`.
- Inspect DevStack logs: `/opt/stack/logs/stack.sh.log` inside each container.
- Ensure nested virtualization is available: `egrep -c '(vmx|svm)' /proc/cpuinfo` should be > 0.
- If proxy ports fail to bind, make sure no conflicting processes listen on the host.
- Use `FORCE_REDEPLOY=true` when you want a clean redeployment of all clouds.

---

With this script and guide you can maintain three independent OpenStack environments on a single box for testing, demos, or multi-region experimentation. Customize the networks or add services as needed for your scenarios.
