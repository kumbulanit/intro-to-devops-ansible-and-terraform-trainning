Here’s a detailed Ansible playbook to create a VM using all the required OpenStack components (network, subnet, router, security group, keypair, floating IP, server) on DevStack hosted at http://10.0.3.15 (assuming Horizon/OpenStack API is accessible at that IP).

We’ll use the OpenStack collection via openstacksdk and clouds.yaml. This guide includes:
•	clouds.yaml setup
•	Required OpenStack resources creation
•	VM launch
•	Floating IP assignment
•	Verification

⸻

🧾 1. Prerequisites

On your Ansible Control Node:
•	Python modules: openstacksdk, shade
•	Ansible collections:

pip install openstacksdk
ansible-galaxy collection install openstack.cloud



⸻

📁 2. clouds.yaml configuration

Save this in ~/.config/openstack/clouds.yaml (or define inline in the playbook with env vars).

clouds:
devstack:
auth:
auth_url: http://10.0.3.15/identity
username: admin
password: your_password
project_name: admin
user_domain_name: Default
project_domain_name: Default
region_name: RegionOne
interface: public
identity_api_version: 3

Replace your_password with your real DevStack admin password.

⸻

📜 3. Playbook: create_vm_openstack.yaml

---
- name: Provision VM in DevStack OpenStack
  hosts: localhost
  gather_facts: no
  collections:
    - openstack.cloud

  vars:
  cloud: devstack
  image_name: "cirros"
  flavor_name: "m1.small"
  network_name: "demo-net"
  subnet_name: "demo-subnet"
  router_name: "demo-router"
  keypair_name: "demo-key"
  secgroup_name: "demo-secgroup"
  server_name: "demo-vm"
  floating_ip_network: "public"

  tasks:
    - name: Create network
      openstack.cloud.network:
      cloud: "{{ cloud }}"
      name: "{{ network_name }}"

    - name: Create subnet
      openstack.cloud.subnet:
      cloud: "{{ cloud }}"
      name: "{{ subnet_name }}"
      network_name: "{{ network_name }}"
      cidr: 192.168.100.0/24
      ip_version: 4
      dns_nameservers:
      - 8.8.8.8
      gateway_ip: 192.168.100.1

    - name: Create router
      openstack.cloud.router:
      cloud: "{{ cloud }}"
      name: "{{ router_name }}"
      network: "{{ floating_ip_network }}"

    - name: Attach subnet to router
      openstack.cloud.router:
      cloud: "{{ cloud }}"
      name: "{{ router_name }}"
      state: present
      interfaces:
      - "{{ subnet_name }}"

    - name: Create security group
      openstack.cloud.security_group:
      cloud: "{{ cloud }}"
      name: "{{ secgroup_name }}"
      description: "Security group for demo VM"

    - name: Add SSH rule to security group
      openstack.cloud.security_group_rule:
      cloud: "{{ cloud }}"
      security_group: "{{ secgroup_name }}"
      protocol: tcp
      port_range_min: 22
      port_range_max: 22
      direction: ingress
      remote_ip_prefix: 0.0.0.0/0

    - name: Add ICMP rule to security group
      openstack.cloud.security_group_rule:
      cloud: "{{ cloud }}"
      security_group: "{{ secgroup_name }}"
      protocol: icmp
      direction: ingress
      remote_ip_prefix: 0.0.0.0/0

    - name: Create keypair
      openstack.cloud.keypair:
      cloud: "{{ cloud }}"
      name: "{{ keypair_name }}"
      public_key_file: "~/.ssh/id_rsa.pub"

    - name: Launch server
      openstack.cloud.server:
      cloud: "{{ cloud }}"
      state: present
      name: "{{ server_name }}"
      image: "{{ image_name }}"
      flavor: "{{ flavor_name }}"
      key_name: "{{ keypair_name }}"
      network: "{{ network_name }}"
      security_groups:
      - "{{ secgroup_name }}"

    - name: Allocate floating IP
      openstack.cloud.floating_ip:
      cloud: "{{ cloud }}"
      network: "{{ floating_ip_network }}"
      register: fip

    - name: Associate floating IP to instance
      openstack.cloud.server:
      cloud: "{{ cloud }}"
      name: "{{ server_name }}"
      network: "{{ network_name }}"
      floating_ips:
      - "{{ fip.floating_ip.floating_ip_address }}"

    - name: Show public IP
      debug:
      msg: "Floating IP assigned: {{ fip.floating_ip.floating_ip_address }}"


⸻

✅ 4. Verification Steps

After running the playbook:
1.	Use SSH (if image supports it):

ssh -i ~/.ssh/id_rsa cirros@{{ fip.floating_ip.floating_ip_address }}


	2.	Ping the IP:

ping {{ fip.floating_ip.floating_ip_address }}


	3.	Visit http://10.0.3.15 and navigate to Horizon → Instances to verify.

⸻

