# 🎓 Hands-On Lab: OpenStack Automation with Ansible SDK and Modules


## 📘 Exercise 1: Separate Networks for Ubuntu and CentOS

```yaml
# exercise1_separate_networks.yml
- name: Deploy VMs with separate networks per OS
  hosts: localhost
  collections:
    - openstack.cloud
  vars_files:
    - group_vars/all.yml
  tasks:
    - name: Create Ubuntu network
      openstack.cloud.network:
        cloud: "{{ cloud_name }}"
        name: "ubuntu-net"

    - name: Create CentOS network
      openstack.cloud.network:
        cloud: "{{ cloud_name }}"
        name: "centos-net"

    - name: Create Ubuntu subnet
      openstack.cloud.subnet:
        cloud: "{{ cloud_name }}"
        name: "ubuntu-subnet"
        network_name: ubuntu-net
        cidr: 192.168.111.0/24

    - name: Create CentOS subnet
      openstack.cloud.subnet:
        cloud: "{{ cloud_name }}"
        name: "centos-subnet"
        network_name: centos-net
        cidr: 192.168.222.0/24

    - name: Create routers
      openstack.cloud.router:
        cloud: "{{ cloud_name }}"
        name: "{{ item.name }}"
        network: public
        interfaces:
          - subnet: "{{ item.subnet }}"
      loop:
        - { name: "ubuntu-router", subnet: "ubuntu-subnet" }
        - { name: "centos-router", subnet: "centos-subnet" }

    - name: Create Ubuntu security group
      openstack.cloud.security_group:
        cloud: "{{ cloud_name }}"
        name: ubuntu-sec

    - name: Create CentOS security group
      openstack.cloud.security_group:
        cloud: "{{ cloud_name }}"
        name: centos-sec

    - name: Create Ubuntu VM
      openstack.cloud.server:
        cloud: "{{ cloud_name }}"
        name: ubuntu-net-vm
        image: "{{ image_name_ubuntu }}"
        flavor: "{{ flavor }}"
        key_name: "{{ keypair }}"
        network: ubuntu-net
        security_groups:
          - ubuntu-sec

    - name: Create CentOS VM
      openstack.cloud.server:
        cloud: "{{ cloud_name }}"
        name: centos-net-vm
        image: "{{ image_name_centos }}"
        flavor: "{{ flavor }}"
        key_name: "{{ keypair }}"
        network: centos-net
        security_groups:
          - centos-sec
```

Run:

```bash
ansible-playbook -i inventory.ini exercise1_separate_networks.yml
```

---

## 📘 Exercise 2: Jinja2 Templated Dynamic VM Creation

```yaml
# exercise2_dynamic_vm_template.yml
- name: Launch dynamic VMs from OS list
  hosts: localhost
  collections:
    - openstack.cloud
  vars:
    cloud_name: devstack
    keypair: mykey
    flavor: m1.small
    os_definitions:
      - name: ubuntu-jinja
        image: ubuntu-22.04
        net: demo-net
        sg: demo-secgroup
      - name: centos-jinja
        image: centos-9-stream
        net: demo-net
        sg: demo-secgroup
  tasks:
    - name: Launch VMs using loop
      openstack.cloud.server:
        cloud: "{{ cloud_name }}"
        name: "{{ item.name }}"
        image: "{{ item.image }}"
        flavor: "{{ flavor }}"
        key_name: "{{ keypair }}"
        network: "{{ item.net }}"
        security_groups:
          - "{{ item.sg }}"
      loop: "{{ os_definitions }}"
```

Run:

```bash
ansible-playbook -i inventory.ini exercise2_dynamic_vm_template.yml
```

---

## 📘 Exercise 3: Attach Floating IPs to VMs

```yaml
# exercise3_floating_ips.yml
- name: Allocate and associate floating IPs to VMs
  hosts: localhost
  collections:
    - openstack.cloud
  vars:
    cloud_name: devstack
    public_network: public
    servers:
      - name: ubuntu-net-vm
      - name: centos-net-vm
  tasks:
    - name: Allocate floating IP and assign
      block:
        - name: Allocate floating IP
          openstack.cloud.floating_ip:
            cloud: "{{ cloud_name }}"
            network: "{{ public_network }}"
          register: fip

        - name: Associate IP
          openstack.cloud.server:
            cloud: "{{ cloud_name }}"
            name: "{{ item.name }}"
            network: demo-net
            auto_ip: no
            reuse_ips: false
            timeout: 300
            wait: yes
            floating_ips:
              - "{{ fip.floating_ip.ip }}"
      loop: "{{ servers }}"
```

Run:

```bash
ansible-playbook -i inventory.ini exercise3_floating_ips.yml
```

