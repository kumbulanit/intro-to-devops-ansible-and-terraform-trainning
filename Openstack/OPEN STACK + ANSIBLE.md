# 💪 Full Hands-On Lab: OpenStack DevStack + Ansible Automation (Start to Teardown)

This hands-on lab walks you through installing OpenStack DevStack on a single Ubuntu instance, configuring Ansible with OpenStack modules, deploying infrastructure resources, and then tearing everything down.

---

## 📆 Total Duration: 1 Hour

| Task   | Description                            | Time    |
| ------ | -------------------------------------- | ------- |
| Part 1 | System Preparation and Prerequisites   | 10 mins |
| Part 2 | Install and Configure DevStack         | 15 mins |
| Part 3 | Install Ansible and SDK + Setup        | 10 mins |
| Part 4 | Use Ansible Modules (One Per Playbook) | 15 mins |
| Part 5 | Use Combined Playbook                  | 5 mins  |
| Part 6 | Teardown Stack                         | 5 mins  |

---

## 🛠️ Part 1: System Preparation (10 mins)

### 1.1 Requirements

* Ubuntu 20.04/22.04
* 8GB RAM, 2 CPUs, 50GB disk
* Internet access

### 1.2 Update System

```bash
sudo apt update && sudo apt upgrade -y
```

### 1.3 Install Dependencies

```bash
sudo apt install git python3-pip python3-venv -y
```

---

## 🔧 Part 2: Install and Configure DevStack (15 mins)

### 2.1 Create `stack` User

```bash
sudo useradd -s /bin/bash -d /opt/stack -m stack
sudo passwd stack
```

Grant `stack` sudo access:

```bash
echo "stack ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/stack
```

### 2.2 Switch to Stack User and Clone DevStack

```bash
sudo su - stack
git clone https://opendev.org/openstack/devstack
cd devstack
```

### 2.3 Create `local.conf` File

```bash
cat <<EOF > local.conf
[[local|localrc]]
ADMIN_PASSWORD=devstack
DATABASE_PASSWORD=devstack
RABBIT_PASSWORD=devstack
SERVICE_PASSWORD=devstack
HOST_IP=$(hostname -I | cut -d' ' -f1)
EOF
```

### 2.4 Start the Installer

```bash
./stack.sh
```

> Access dashboard at: http\://\<your\_ip>/dashboard — Login: `admin` / `devstack`

---

## 🧰 Part 3: Set Up Ansible and OpenStack SDK (10 mins)

### 3.1 Create Virtual Environment and Install Tools

```bash
python3 -m venv ~/ansible-env
source ~/ansible-env/bin/activate
pip install ansible openstacksdk
ansible-galaxy collection install openstack.cloud
```

### 3.2 Configure clouds.yaml

```bash
mkdir -p ~/.config/openstack

cat <<EOF > ~/.config/openstack/clouds.yaml
clouds:
  devstack:
    auth:
      auth_url: http://127.0.0.1/identity
      username: admin
      password: devstack
      project_name: admin
      user_domain_name: Default
      project_domain_name: Default
    region_name: RegionOne
    interface: public
    identity_api_version: 3
EOF
```

---

## 📘 Part 4: Ansible Module Playbooks (Run Each Separately - 15 mins)

Each playbook performs one task. You can run and destroy them individually by changing `state:` between `present` and `absent`.

### ✅ Create Network - `os_network.yml`

```yaml
- name: Create Network
  hosts: localhost
  tasks:
    - name: Create internal network
      openstack.cloud.network:
        cloud: devstack
        name: internal-net
        external: false
        shared: false
        state: present
```

### ✅ Create Subnet - `os_subnet.yml`

```yaml
- name: Create Subnet
  hosts: localhost
  tasks:
    - name: Create subnet for internal-net
      openstack.cloud.subnet:
        cloud: devstack
        name: internal-subnet
        network_name: internal-net
        cidr: 192.168.100.0/24
        ip_version: 4
        enable_dhcp: true
        dns_nameservers: [8.8.8.8]
        state: present
```

### ✅ Create Router - `os_router.yml`

```yaml
- name: Create Router
  hosts: localhost
  tasks:
    - name: Create and attach router
      openstack.cloud.router:
        cloud: devstack
        name: internal-router
        network: public
        interfaces:
          - subnet: internal-subnet
        state: present
```

### ✅ Create Security Group - `os_security_group.yml`

```yaml
- name: Create Security Group
  hosts: localhost
  tasks:
    - name: Create web-secgroup
      openstack.cloud.security_group:
        cloud: devstack
        name: web-secgroup
        description: Allow SSH and HTTP
        state: present
```

### ✅ Add Rules - `os_security_group_rule.yml`

```yaml
- name: Add Rules to Security Group
  hosts: localhost
  tasks:
    - name: Allow SSH
      openstack.cloud.security_group_rule:
        cloud: devstack
        security_group: web-secgroup
        protocol: tcp
        port_range_min: 22
        port_range_max: 22
        direction: ingress
        remote_ip_prefix: 0.0.0.0/0
        state: present

    - name: Allow HTTP
      openstack.cloud.security_group_rule:
        cloud: devstack
        security_group: web-secgroup
        protocol: tcp
        port_range_min: 80
        port_range_max: 80
        direction: ingress
        remote_ip_prefix: 0.0.0.0/0
        state: present
```

### ✅ Launch Server - `os_server.yml`

```yaml
- name: Launch Instance
  hosts: localhost
  tasks:
    - name: Create server
      openstack.cloud.server:
        cloud: devstack
        name: web-server
        image: cirros
        flavor: m1.tiny
        key_name: demo-key
        network: internal-net
        security_groups:
          - web-secgroup
        state: present
```

### ✅ Server Action - `os_server_action.yml`

```yaml
- name: Perform Server Action
  hosts: localhost
  tasks:
    - name: Reboot the server
      openstack.cloud.server_action:
        cloud: devstack
        server: web-server
        action: reboot
        reboot_type: HARD
```

---

## 🚀 Part 5: Full Deployment Playbook - `deploy_stack.yml` (5 mins)

Run after teardown to deploy all in one go:

```bash
ansible-playbook deploy_stack.yml
```

---

## 🧼 Part 6: Teardown Playbook - `teardown_stack.yml` (5 mins)

To destroy all resources:

```bash
ansible-playbook teardown_stack.yml
```

### Contents of `teardown_stack.yml`

```yaml
- name: Destroy Full OpenStack Stack
  hosts: localhost
  tasks:
    - name: Delete server
      openstack.cloud.server:
        cloud: devstack
        name: web-server
        state: absent

    - name: Remove security rules
      block:
        - name: Delete SSH rule
          openstack.cloud.security_group_rule:
            cloud: devstack
            security_group: web-secgroup
            protocol: tcp
            port_range_min: 22
            port_range_max: 22
            direction: ingress
            remote_ip_prefix: 0.0.0.0/0
            state: absent

        - name: Delete HTTP rule
          openstack.cloud.security_group_rule:
            cloud: devstack
            security_group: web-secgroup
            protocol: tcp
            port_range_min: 80
            port_range_max: 80
            direction: ingress
            remote_ip_prefix: 0.0.0.0/0
            state: absent

    - name: Delete security group
      openstack.cloud.security_group:
        cloud: devstack
        name: web-secgroup
        state: absent

    - name: Detach and delete router
      openstack.cloud.router:
        cloud: devstack
        name: internal-router
        interfaces:
          - subnet: internal-subnet
        state: absent

    - name: Delete subnet
      openstack.cloud.subnet:
        cloud: devstack
        name: internal-subnet
        network_name: internal-net
        state: absent

    - name: Delete network
      openstack.cloud.network:
        cloud: devstack
        name: internal-net
        state: absent
```

---

## 🔍 Validate

```bash
openstack server list
openstack network list
openstack subnet list
openstack router list
openstack security group list
```

All results should return empty if the teardown was successful.

---

## 📘 Summary

* You installed DevStack, configured Ansible, and ran OpenStack module playbooks.
* You deployed infrastructure with individual and full-stack playbooks.
* You cleaned up all resources using a dedicated teardown playbook.


