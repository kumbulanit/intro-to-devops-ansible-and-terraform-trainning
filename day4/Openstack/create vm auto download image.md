Excellent. Let’s upgrade the playbook to:

✅ Automatically download the image (if missing)
✅ Automatically generate a keypair (if it doesn’t exist) and its private key (if not present locally)

We’ll use os_image_facts, stat, shell, and Ansible’s lookup('file') to implement logic with conditionals.

⸻

✅ UPDATED PLAYBOOK: create_vm_openstack.yaml
```yaml
---
- name: Provision VM in DevStack with auto-download and auto-keypair
  hosts: localhost
  gather_facts: false
  collections:
    - openstack.cloud

  vars:
  cloud: devstack
  image_name: cirros
  image_url: https://download.cirros-cloud.net/0.6.2/cirros-0.6.2-x86_64-disk.img
  image_file: /tmp/cirros-0.6.2-x86_64-disk.img

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

    - name: Check if image exists
      openstack.cloud.image_info:
      cloud: "{{ cloud }}"
      name: "{{ image_name }}"
      register: image_info

    - name: Download image if not found
      get_url:
      url: "{{ image_url }}"
      dest: "{{ image_file }}"
      mode: '0644'
      when: image_info.images | length == 0

    - name: Upload image if not found
      openstack.cloud.image:
      cloud: "{{ cloud }}"
      name: "{{ image_name }}"
      disk_format: qcow2
      container_format: bare
      filename: "{{ image_file }}"
      when: image_info.images | length == 0

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

    - name: Assign floating IP to server
      openstack.cloud.server:
      cloud: "{{ cloud }}"
      name: "{{ server_name }}"
      network: "{{ network_name }}"
      floating_ips:
      - "{{ fip.floating_ip.floating_ip_address }}"

    - name: Show public IP
      debug:
      msg: "Floating IP is: {{ fip.floating_ip.floating_ip_address }}"
```

⸻

🧪 TESTING

To test the updated logic:
1.	Delete the image in Horizon or CLI:
```bash
openstack image delete cirros
```

2.	Remove local SSH key (optional test):
```bash
rm -f ~/.ssh/demo-key ~/.ssh/demo-key.pub
```

3.	Run the playbook again:
```bash
ansible-playbook -i inventory.yaml create_vm_openstack.yaml
```


