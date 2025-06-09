Ansible playbook that:

✅ Downloads and uploads Cirros, Ubuntu 22.04, and CentOS 9 images
✅ Creates the required network, subnet, router, keypair, security group
✅ Automatically generates an SSH keypair if not present
✅ Launches a VM using your selected image
✅ Associates a floating IP correctly using the server ID
✅ Outputs both internal and external IP addresses

⸻

✅ Full Playbook: create_vm_openstack.yaml
```yaml
---
- name: Provision VM in DevStack with 3 auto-downloaded images
  hosts: localhost
  gather_facts: false
  collections:
    - openstack.cloud

  vars:
  cloud: devstack

  images:
  - name: cirros
  url: https://download.cirros-cloud.net/0.6.2/cirros-0.6.2-x86_64-disk.img
  file: /tmp/cirros-0.6.2-x86_64-disk.img
  format: qcow2
  - name: ubuntu-22.04
  url: https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.img
  file: /tmp/ubuntu-22.04-server-cloudimg-amd64.img
  format: qcow2
  - name: centos-9
  url: https://cloud.centos.org/centos/9-stream/x86_64/images/CentOS-Stream-GenericCloud-9-latest.x86_64.qcow2
  file: /tmp/CentOS-Stream-GenericCloud-9-latest.x86_64.qcow2
  format: qcow2

  image_name: ubuntu-22.04  # Change to centos-9 or cirros to use different base image
  flavor_name: m1.small
  network_name: demo-net
  subnet_name: demo-subnet
  router_name: demo-router
  keypair_name: demo-key
  keypair_private_key: ~/.ssh/demo-key
  keypair_public_key: "{{ keypair_private_key }}.pub"
  secgroup_name: demo-secgroup
  server_name: demo-vm
  floating_ip_network: public

  tasks:

    - name: Get image info for each image
      openstack.cloud.image_info:
      cloud: "{{ cloud }}"
      name: "{{ item.name }}"
      loop: "{{ images }}"
      register: image_results

    - name: Zip images with their info results
      set_fact:
      image_data: "{{ images | zip(image_results.results) | list }}"

    - name: Download image if not found
      get_url:
      url: "{{ item.0.url }}"
      dest: "{{ item.0.file }}"
      mode: '0644'
      when: (item.1.images | length) == 0
      loop: "{{ image_data }}"
      loop_control:
      label: "{{ item.0.name }}"

    - name: Upload image if not found
      openstack.cloud.image:
      cloud: "{{ cloud }}"
      name: "{{ item.0.name }}"
      disk_format: "{{ item.0.format }}"
      container_format: bare
      filename: "{{ item.0.file }}"
      when: (item.1.images | length) == 0
      loop: "{{ image_data }}"
      loop_control:
      label: "{{ item.0.name }}"

    - name: Check if keypair file exists
      stat:
      path: "{{ keypair_private_key }}"
      register: key_stat

    - name: Generate SSH keypair locally if not exists
      shell: |
      ssh-keygen -t rsa -b 2048 -f {{ keypair_private_key }} -N ""
      when: not key_stat.stat.exists

    - name: Read public key
      slurp:
      src: "{{ keypair_public_key }}"
      register: pubkey_file

    - name: Ensure keypair exists in OpenStack
      openstack.cloud.keypair:
      cloud: "{{ cloud }}"
      name: "{{ keypair_name }}"
      public_key: "{{ pubkey_file.content | b64decode }}"

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
      gateway_ip: 192.168.100.1
      dns_nameservers:
      - 8.8.8.8

    - name: Create router
      openstack.cloud.router:
      cloud: "{{ cloud }}"
      name: "{{ router_name }}"
      network: "{{ floating_ip_network }}"

    - name: Attach subnet to router
      openstack.cloud.router:
      cloud: "{{ cloud }}"
      name: "{{ router_name }}"
      interfaces:
      - "{{ subnet_name }}"

    - name: Create security group
      openstack.cloud.security_group:
      cloud: "{{ cloud }}"
      name: "{{ secgroup_name }}"
      description: Security group for demo VM

    - name: Allow SSH in security group
      openstack.cloud.security_group_rule:
      cloud: "{{ cloud }}"
      security_group: "{{ secgroup_name }}"
      protocol: tcp
      port_range_min: 22
      port_range_max: 22
      direction: ingress
      remote_ip_prefix: 0.0.0.0/0

    - name: Allow ping (ICMP)
      openstack.cloud.security_group_rule:
      cloud: "{{ cloud }}"
      security_group: "{{ secgroup_name }}"
      protocol: icmp
      direction: ingress
      remote_ip_prefix: 0.0.0.0/0

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

    - name: Get the server info
      openstack.cloud.server_info:
      cloud: "{{ cloud }}"
      name: "{{ server_name }}"
      register: server_info

    - name: Associate floating IP with server
      openstack.cloud.floating_ip_associate:
      cloud: "{{ cloud }}"
      server: "{{ server_info.servers[0].id }}"
      floating_ip: "{{ fip.floating_ip.floating_ip_address }}"

    - name: Show server internal and floating IPs
      debug:
      msg:
      - "Floating IP: {{ fip.floating_ip.floating_ip_address }}"
      - "Internal IPs: {{ server_info.servers[0].addresses }}"

```
⸻

✅ Inventory File: inventory.yaml
```ini
all:
hosts:
localhost:
ansible_connection: local
```

⸻

🚀 How to Run
```bash
ansible-playbook -i inventory.yaml create_vm_openstack.yaml
```
This will create all resources, launch the VM with Ubuntu 22.04 by default, and associate a floating IP.

⸻
