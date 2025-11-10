# Three DevStack Clouds on One Host

This guide explains how to spin up three isolated OpenStack (DevStack) environments on a single Ubuntu machine using the helper script `deploy_three_devstacks.sh`. Each environment runs inside its own LXD container with unique API ports and dashboard URL, so they can coexist without conflicts.

## 1. Prerequisites

- Ubuntu 22.04 LTS host with:
  - At least 16 vCPUs (or 8 physical cores with SMT)
  - 32 GB RAM minimum; 48 GB+ recommended if you plan to run all services simultaneously
  - 200 GB of free disk space (DevStack clones and backing storage for three clouds)
- Passwordless sudo access for your user
- Working internet connection (to clone DevStack repositories and download packages)
- LXD available on the host (the script installs and initialises it if missing)

> **Tip:** DevStack is intended for development and testing only. For production-grade, multi-instance deployments, consider Kolla-Ansible or OpenStack-Ansible instead.

## 2. Obtain the Script

```bash
cd /Users/kumbulani/Desktop/ansible_trainning/intro-to-devops-ansible-and-terraform-trainning/day4/Openstack/scripts
chmod +x deploy_three_devstacks.sh
```

## 3. Configuration (Optional)

The script exposes several knobs through environment variables:

- `CLOUD_COUNT` – how many clouds to provision (default: 3)
- `BASE_NAME` – container name prefix (default: `openstack-lab`)
- `RELEASE` – DevStack git branch (default: `stable/2024.2`)
- `RUN_STACK` – set to `1` to run `stack.sh` automatically inside each container (default: `0`)
- `ADMIN_PASSWORD`, `SERVICE_PASSWORD`, `DATABASE_PASSWORD`, `RABBIT_PASSWORD` – credentials for every cloud
- `KEYSTONE_BASE_PORT` and `HORIZON_BASE_PORT` – starting ports for Keystone and Horizon (incremented by `PORT_STEP` for each additional cloud)

Example: adjust the admin password and trigger automatic DevStack installation.

```bash
export ADMIN_PASSWORD='Sup3rSecret!'
export RUN_STACK=1
./deploy_three_devstacks.sh
```

## 4. Run the Deployment

```bash
./deploy_three_devstacks.sh
```

What happens:

1. LXD is installed/initialised if needed.
2. Three containers named `openstack-lab-1`, `openstack-lab-2`, and `openstack-lab-3` are launched from the `ubuntu:22.04` image.
3. Each container receives a DevStack clone plus a tailored `local.conf` with unique Keystone and Horizon ports.
4. If `RUN_STACK=1`, the script fires `stack.sh` (20–40 minutes per cloud). Otherwise, it prints manual commands to run later.

A summary similar to the following appears at the end:

```text
Cloud 1: openstack-lab-1
  Container IP: 10.200.31.101
  Keystone URL: http://10.200.31.101:5000/v3
  Horizon URL:  http://10.200.31.101:8080/
  Credentials:  admin / stackadmin
...
```

## 5. Finish DevStack Install (if you skipped auto-run)

For each cloud where `stack.sh` was skipped:

```bash
lxc exec openstack-lab-1 -- sudo -u stack bash -lc 'cd devstack && ./stack.sh'
```

Expect the first run to take ~30 minutes. Repeat for the other containers.

## 6. Validate Services

Inside each container (substitute the name):

```bash
lxc exec openstack-lab-1 -- sudo -u stack bash -lc 'source devstack/openrc admin admin && openstack token issue'
```

You should receive a token containing the unique Keystone endpoint for that cloud.

## 7. Access the Dashboards

Open a browser from your workstation and navigate to the Horizon URL reported by the script, for example:

- Cloud 1: `http://10.200.31.101:8080/`
- Cloud 2: `http://10.200.31.102:8120/`
- Cloud 3: `http://10.200.31.103:8160/`

> Port offsets come from `PORT_STEP` (default 20). You can change both the base ports and the increment before running the script.

Log in with `admin` plus the password you set (default: `stackadmin`).

## 8. Add Entries to clouds.yaml (Optional)

Update `~/.config/openstack/clouds.yaml` on your workstation to manage the clouds via the OpenStack client:

```yaml
clouds:
  lab1:
    auth:
      auth_url: http://10.200.31.101:5000/v3
      username: admin
      password: stackadmin
      project_name: admin
      user_domain_name: Default
      project_domain_name: Default
    region_name: RegionOne
    interface: public
    identity_api_version: 3
  lab2:
    auth:
      auth_url: http://10.200.31.102:5020/v3
      ...
  lab3:
    auth:
      auth_url: http://10.200.31.103:5040/v3
      ...
```

(Replace IPs, ports, and passwords as required.)

## 9. Teardown

To remove an environment:

```bash
lxc stop openstack-lab-1
lxc delete openstack-lab-1
```

Delete DevStack logs or snapshots as needed. DevStack also ships with `unstack.sh` and `clean.sh` for in-place cleanup if you want to recycle the container instead of destroying it.

## 10. Troubleshooting

- **Ports already in use:** Adjust `KEYSTONE_BASE_PORT`, `HORIZON_BASE_PORT`, or `PORT_STEP` before running the script.
- **Insufficient RAM:** DevStack can fail when memory is tight. Shut down unused services or increase host memory.
- **LXD permission denied:** Log out/in after the script adds your user to the `lxd` group, or run `newgrp lxd` in the same shell.
- **Service start failures after stack.sh:** Inspect `~/devstack/logs/*.log` inside the container. Re-run `./stack.sh` after fixing issues.

With these steps, you can run three independent OpenStack labs side by side on a single machine, each with distinct API endpoints and dashboards for experimentation.
