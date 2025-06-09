# 🎓 Hands-On Lab: OpenStack Automation with Ansible SDK and Modules

(...existing content...)

---

## 🧠 Bonus Complex Exercise: Full Multi-Tier Application with Isolation and FIP

### 🔍 Scenario:

You are asked to deploy a web application stack in OpenStack using Ansible. The setup should:

* Create **two isolated networks** (frontend and backend)
* Launch **frontend VM (Ubuntu)** and **backend VM (CentOS)**
* Use **routers**, **security groups**, **floating IPs**, and **server actions**
* Use **Ansible variables**, **looping**, and **Jinja2 templating**

---

### ✅ Exercise 4: Multi-Tier Web App Deployment with Full Isolation

```yaml
# ex4_multitier_app.yml
- name: Deploy multi-tier web app using OpenStack modules
  hosts: localhost
  collections:
    - openstack.cloud
  vars:
    cloud: devstack
    flavor: m1.small
    keypair: mykey
    public_net: public

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

  tasks:
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

    - name: Create routers
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

### 📝 Explanation of Each Block

| Step                        | Purpose                                         |
| --------------------------- | ----------------------------------------------- |
| `networks:` var             | Stores both frontend and backend network info   |
| `network + subnet creation` | Isolates each tier of the app                   |
| `router creation`           | Connects each private subnet to public internet |
| `security_group + rules`    | Allows SSH and HTTP (frontend only)             |
| `server:`                   | Launches VMs dynamically per tier               |
| `floating_ip`               | Attaches public IP to frontend only             |
| `server_action`             | Reboots backend to simulate patching            |

---

### ▶️ Run It

```bash
ansible-playbook -i inventory.ini ex4_multitier_app.yml
```

---

✅ This advanced exercise integrates all 7 OpenStack modules and demonstrates secure, production-like multi-tier deployments. Would you like to include a teardown playbook or verification ping/ssh test?
