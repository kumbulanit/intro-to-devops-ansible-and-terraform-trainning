# 🎓 Hands-On Lab: OpenStack Automation with Ansible SDK and Modules (Role-Based)

(...existing content...)

---

## 🔁 Converting All OpenStack Tasks into a Reusable Ansible Role

We'll now modularize all OpenStack provisioning into a role called `openstack_vm_infra`.

### 🗂️ Role Directory Structure

```bash
roles/
└── openstack_vm_infra/
    ├── defaults/
    │   └── main.yml
    ├── tasks/
    │   └── main.yml
    └── vars/
        └── main.yml
```

---

### 📝 Step 1: Create the Role

```bash
ansible-galaxy init roles/openstack_vm_infra
```

---

### 📄 `defaults/main.yml`

```yaml
cloud: devstack
public_net: public
flavor: m1.small
keypair: mykey
image_ubuntu: ubuntu-22.04
image_centos: centos-9-stream
```

---

### 📄 `vars/main.yml`

```yaml
networks:
  - name: frontend-net
    subnet: frontend-subnet
    cidr: 192.168.10.0/24
    router: frontend-router
    vm:
      name: frontend-vm
      image: ubuntu-22.04
      secgroup: frontend-sg

  - name: backend-net
    subnet: backend-subnet
    cidr: 192.168.20.0/24
    router: backend-router
    vm:
      name: backend-vm
      image: centos-9-stream
      secgroup: backend-sg
```

---

### 📄 `tasks/main.yml`

```yaml
- name: Create networks and subnets
  loop: "{{ networks }}"
  loop_control:
    label: "{{ item.name }}"
  block:
    - name: Create network
      openstack.cloud.network:
        cloud: "{{ cloud }}"
        name: "{{ item.name }}"

    - name: Create subnet
      openstack.cloud.subnet:
        cloud: "{{ cloud }}"
        name: "{{ item.subnet }}"
        network_name: "{{ item.name }}"
        cidr: "{{ item.cidr }}"

- name: Create routers and attach subnets
  loop: "{{ networks }}"
  openstack.cloud.router:
    cloud: "{{ cloud }}"
    name: "{{ item.router }}"
    network: "{{ public_net }}"
    interfaces:
      - subnet: "{{ item.subnet }}"

- name: Create security groups with access rules
  loop:
    - { name: frontend-sg, ports: [22, 80] }
    - { name: backend-sg, ports: [22] }
  block:
    - name: Create SG
      openstack.cloud.security_group:
        cloud: "{{ cloud }}"
        name: "{{ item.name }}"

    - name: Add port rules
      loop: "{{ item.ports }}"
      openstack.cloud.security_group_rule:
        cloud: "{{ cloud }}"
        security_group: "{{ item.name }}"
        protocol: tcp
        port_range_min: "{{ item2 }}"
        port_range_max: "{{ item2 }}"
        direction: ingress
      loop_control:
        loop_var: item2

- name: Launch frontend and backend VMs
  loop: "{{ networks }}"
  openstack.cloud.server:
    cloud: "{{ cloud }}"
    name: "{{ item.vm.name }}"
    image: "{{ item.vm.image }}"
    flavor: "{{ flavor }}"
    key_name: "{{ keypair }}"
    network: "{{ item.name }}"
    security_groups:
      - "{{ item.vm.secgroup }}"

- name: Allocate and associate floating IP for frontend only
  openstack.cloud.floating_ip:
    cloud: "{{ cloud }}"
    network: "{{ public_net }}"
  register: frontend_fip

- name: Attach FIP to frontend-vm
  openstack.cloud.server:
    cloud: "{{ cloud }}"
    name: frontend-vm
    auto_ip: no
    floating_ips:
      - "{{ frontend_fip.floating_ip.ip }}"

- name: Reboot backend-vm using HARD reboot (simulate update)
  openstack.cloud.server_action:
    cloud: "{{ cloud }}"
    server: backend-vm
    action: reboot
    reboot_type: HARD
```

---

### 📘 New Playbook to Use the Role

```yaml
# play_openstack_role.yml
- name: Deploy full OpenStack infrastructure using role
  hosts: localhost
  connection: local
  gather_facts: false
  roles:
    - openstack_vm_infra
```

### ▶️ Run It

```bash
ansible-playbook -i localhost, play_openstack_role.yml
```

✅ You’ve now modularized all OpenStack provisioning into a clean, reusable role!
