# 🎓 Hands-On Lab: OpenStack Automation with Ansible SDK and Modules

(...existing content...)

---

## 🔁 Extended Exercises Showcasing All Key OpenStack Modules

Each of the following exercises demonstrates the full spectrum of OpenStack Ansible modules:

* `os_network`
* `os_subnet`
* `os_router`
* `os_server`
* `os_server_action`
* `os_security_group`
* `os_security_group_rule`

### ✅ Exercise 1: Simple Scenario – Isolated Networks per OS

```yaml
# ex1_isolated_networks.yml
- name: Create isolated networks and VMs for Ubuntu and CentOS
  hosts: localhost
  collections:
    - openstack.cloud
  vars:
    cloud: devstack
    keypair: mykey
    flavor: m1.small
    image_ubuntu: ubuntu-22.04
    image_centos: centos-9-stream
  tasks:
    - name: Create networks and subnets
      block:
        - name: Create network for Ubuntu
          openstack.cloud.network:
            cloud: "{{ cloud }}"
            name: net-ubuntu

        - name: Create subnet for Ubuntu
          openstack.cloud.subnet:
            cloud: "{{ cloud }}"
            name: subnet-ubuntu
            network_name: net-ubuntu
            cidr: 10.10.1.0/24

        - name: Create network for CentOS
          openstack.cloud.network:
            cloud: "{{ cloud }}"
            name: net-centos

        - name: Create subnet for CentOS
          openstack.cloud.subnet:
            cloud: "{{ cloud }}"
            name: subnet-centos
            network_name: net-centos
            cidr: 10.10.2.0/24

    - name: Create routers and attach subnets
      loop:
        - { name: router-ubuntu, subnet: subnet-ubuntu }
        - { name: router-centos, subnet: subnet-centos }
      openstack.cloud.router:
        cloud: "{{ cloud }}"
        name: "{{ item.name }}"
        network: public
        interfaces:
          - subnet: "{{ item.subnet }}"

    - name: Create security groups
      loop:
        - name: sg-ubuntu
        - name: sg-centos
      openstack.cloud.security_group:
        cloud: "{{ cloud }}"
        name: "{{ item.name }}"

    - name: Add rules to both SGs
      loop:
        - sg: sg-ubuntu
        - sg: sg-centos
      block:
        - name: Allow SSH
          openstack.cloud.security_group_rule:
            cloud: "{{ cloud }}"
            security_group: "{{ item.sg }}"
            protocol: tcp
            port_range_min: 22
            port_range_max: 22
            direction: ingress
        - name: Allow ICMP
          openstack.cloud.security_group_rule:
            cloud: "{{ cloud }}"
            security_group: "{{ item.sg }}"
            protocol: icmp
            direction: ingress

    - name: Launch VMs
      loop:
        - name: ubuntu-vm
          image: "{{ image_ubuntu }}"
          net: net-ubuntu
          sg: sg-ubuntu
        - name: centos-vm
          image: "{{ image_centos }}"
          net: net-centos
          sg: sg-centos
      openstack.cloud.server:
        cloud: "{{ cloud }}"
        name: "{{ item.name }}"
        image: "{{ item.image }}"
        flavor: "{{ flavor }}"
        key_name: "{{ keypair }}"
        network: "{{ item.net }}"
        security_groups:
          - "{{ item.sg }}"
```

### ✅ Exercise 2: Intermediate – Jinja2-Driven Dynamic VMs

```yaml
# ex2_jinja2_dynamic.yml
- name: Launch multiple VMs using Jinja2 templating
  hosts: localhost
  collections:
    - openstack.cloud
  vars:
    cloud: devstack
    keypair: mykey
    flavor: m1.small
    servers:
      - { name: "vm-jinja-ubuntu", image: "ubuntu-22.04", network: "net-ubuntu", secgroup: "sg-ubuntu" }
      - { name: "vm-jinja-centos", image: "centos-9-stream", network: "net-centos", secgroup: "sg-centos" }
  tasks:
    - name: Create VMs dynamically
      openstack.cloud.server:
        cloud: "{{ cloud }}"
        name: "{{ item.name }}"
        image: "{{ item.image }}"
        flavor: "{{ flavor }}"
        key_name: "{{ keypair }}"
        network: "{{ item.network }}"
        security_groups:
          - "{{ item.secgroup }}"
      loop: "{{ servers }}"
```

### ✅ Exercise 3: Advanced – Assign Floating IPs and Validate

```yaml
# ex3_floating_ip.yml
- name: Allocate floating IPs and associate with VMs
  hosts: localhost
  collections:
    - openstack.cloud
  vars:
    cloud: devstack
    public_net: public
    servers:
      - { name: "ubuntu-vm" }
      - { name: "centos-vm" }
  tasks:
    - name: Allocate and assign FIPs
      block:
        - name: Allocate FIP
          openstack.cloud.floating_ip:
            cloud: "{{ cloud }}"
            network: "{{ public_net }}"
          register: fip

        - name: Assign FIP to instance
          openstack.cloud.server:
            cloud: "{{ cloud }}"
            name: "{{ item.name }}"
            network: "demo-net"
            auto_ip: no
            floating_ips:
              - "{{ fip.floating_ip.ip }}"
      loop: "{{ servers }}"
```

✅ These exercises showcase progressive complexity, network isolation, dynamic deployment, and external access.
