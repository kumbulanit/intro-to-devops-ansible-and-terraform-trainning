# 🎓 Hands-On Lab: OpenStack Automation with Ansible SDK and Modules

This lab demonstrates OpenStack automation with Ansible and the `openstack.cloud` collection. It includes **4 detailed playbooks** showcasing different components (`os_network`, `os_subnet`, `os_router`, `os_server`, `os_server_action`, `os_security_group`, `os_security_group_rule`) in **simple, intermediate, and advanced scenarios** across two operating systems (Ubuntu and CentOS).

---

## ✅ Prerequisites

* A working OpenStack environment (DevStack, PackStack, etc.)
* OpenRC file sourced for API access
* Ansible installed
* OpenStack SDK:

```bash
pip install openstacksdk
ansible-galaxy collection install openstack.cloud
```

---

## 🔍 File Structure

```text
openstack-ansible-lab/
├── inventory.ini
├── 1_simple_vm.yml
├── 2_intermediate_vm.yml
├── 3_advanced_vm.yml
├── 4_vm_action.yml
└── group_vars/
    └── all.yml
```

---

## ✅ Inventory File (localhost only)

```ini
localhost ansible_connection=local
```

---

## ✅ group\_vars/all.yml

```yaml
cloud_name: devstack
region_name: RegionOne
image_name_ubuntu: ubuntu-22.04
image_name_centos: centos-9-stream
flavor: m1.small
network_name: demo-net
subnet_name: demo-subnet
router_name: demo-router
keypair: mykey
security_group: demo-secgroup
```

---

## 📘 1. Simple Scenario: Create Network, Subnet, and VM (Ubuntu)

```yaml
# 1_simple_vm.yml
- name: Simple Network and VM Deployment
  hosts: localhost
  collections:
    - openstack.cloud
  vars_files:
    - group_vars/all.yml
  tasks:
    - name: Create network
      openstack.cloud.network:
        cloud: "{{ cloud_name }}"
        name: "{{ network_name }}"

    - name: Create subnet
      openstack.cloud.subnet:
        cloud: "{{ cloud_name }}"
        name: "{{ subnet_name }}"
        network_name: "{{ network_name }}"
        cidr: 192.168.10.0/24
        dns_nameservers: [8.8.8.8]

    - name: Create router
      openstack.cloud.router:
        cloud: "{{ cloud_name }}"
        name: "{{ router_name }}"
        network: public
        interfaces:
          - subnet: "{{ subnet_name }}"

    - name: Launch Ubuntu VM
      openstack.cloud.server:
        cloud: "{{ cloud_name }}"
        name: ubuntu-vm-simple
        image: "{{ image_name_ubuntu }}"
        flavor: "{{ flavor }}"
        key_name: "{{ keypair }}"
        network: "{{ network_name }}"
```

Run:

```bash
ansible-playbook -i inventory.ini 1_simple_vm.yml
```

---

## 📘 2. Intermediate Scenario: Add Security Groups & Multiple Interfaces

```yaml
# 2_intermediate_vm.yml
- name: Intermediate Scenario with Security Groups
  hosts: localhost
  collections:
    - openstack.cloud
  vars_files:
    - group_vars/all.yml
  tasks:
    - name: Create security group
      openstack.cloud.security_group:
        cloud: "{{ cloud_name }}"
        name: "{{ security_group }}"

    - name: Allow SSH
      openstack.cloud.security_group_rule:
        cloud: "{{ cloud_name }}"
        security_group: "{{ security_group }}"
        protocol: tcp
        port_range_min: 22
        port_range_max: 22
        direction: ingress
        remote_ip_prefix: 0.0.0.0/0

    - name: Create CentOS VM with SG
      openstack.cloud.server:
        cloud: "{{ cloud_name }}"
        name: centos-vm-sec
        image: "{{ image_name_centos }}"
        flavor: "{{ flavor }}"
        key_name: "{{ keypair }}"
        network: "{{ network_name }}"
        security_groups:
          - "{{ security_group }}"
```

Run:

```bash
ansible-playbook -i inventory.ini 2_intermediate_vm.yml
```

---

## 📘 3. Advanced Scenario: Complete Infra with Multiple VMs, SG, Actions

```yaml
# 3_advanced_vm.yml
- name: Advanced VM Deployment with Security, Router, Server Actions
  hosts: localhost
  collections:
    - openstack.cloud
  vars_files:
    - group_vars/all.yml
  tasks:
    - name: Create network, subnet, and router if missing
      block:
        - name: Ensure network exists
          openstack.cloud.network:
            cloud: "{{ cloud_name }}"
            name: "adv-net"

        - name: Ensure subnet exists
          openstack.cloud.subnet:
            cloud: "{{ cloud_name }}"
            name: "adv-subnet"
            network_name: "adv-net"
            cidr: 192.168.99.0/24
            dns_nameservers: [8.8.8.8]

        - name: Ensure router exists and attached
          openstack.cloud.router:
            cloud: "{{ cloud_name }}"
            name: "adv-router"
            network: public
            interfaces:
              - subnet: "adv-subnet"

    - name: Create advanced security group
      openstack.cloud.security_group:
        cloud: "{{ cloud_name }}"
        name: "adv-secgroup"

    - name: Allow HTTP and ICMP
      openstack.cloud.security_group_rule:
        cloud: "{{ cloud_name }}"
        security_group: "adv-secgroup"
        protocol: tcp
        port_range_min: 80
        port_range_max: 80
        direction: ingress

    - name: Allow ping
      openstack.cloud.security_group_rule:
        cloud: "{{ cloud_name }}"
        security_group: "adv-secgroup"
        protocol: icmp
        direction: ingress

    - name: Launch multiple servers (Ubuntu and CentOS)
      openstack.cloud.server:
        cloud: "{{ cloud_name }}"
        name: "{{ item.name }}"
        image: "{{ item.image }}"
        flavor: "{{ flavor }}"
        key_name: "{{ keypair }}"
        network: "adv-net"
        security_groups:
          - adv-secgroup
      loop:
        - { name: "adv-ubuntu", image: "{{ image_name_ubuntu }}" }
        - { name: "adv-centos", image: "{{ image_name_centos }}" }
```

Run:

```bash
ansible-playbook -i inventory.ini 3_advanced_vm.yml
```

---

## 📘 4. Server Action Scenario: Reboot VM

```yaml
# 4_vm_action.yml
- name: Perform Action on a VM
  hosts: localhost
  collections:
    - openstack.cloud
  vars:
    cloud: devstack
  tasks:
    - name: Reboot Ubuntu VM (hard)
      openstack.cloud.server_action:
        cloud: "{{ cloud }}"
        server: adv-ubuntu
        action: reboot
        reboot_type: HARD
```

Run:

```bash
ansible-playbook -i inventory.ini 4_vm_action.yml
```

---

## 🧪 Additional Exercises

### ✅ Exercise 1: Create Separate Network per VM Type

* One network/subnet/router for Ubuntu
* One for CentOS
* Apply separate security groups and observe network isolation

### ✅ Exercise 2: Create a Jinja2-powered template for dynamic VM creation

* Use Jinja2 templating and vars to iterate over OS types

### ✅ Exercise 3: Add Floating IPs to VMs and test external SSH access

* Use `openstack.cloud.floating_ip`
* Attach to VM ports


