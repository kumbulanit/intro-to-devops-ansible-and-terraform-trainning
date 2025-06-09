# 🎓 Hands-On Lab: OpenStack Automation with Ansible SDK and Modules

(...existing content...)

---

## 🔄 Teardown Playbook: Clean Up Resources from Complex Lab

```yaml
# teardown_multitier_app.yml
- name: Teardown OpenStack resources for multi-tier app
  hosts: localhost
  collections:
    - openstack.cloud
  vars:
    cloud: devstack
    servers:
      - frontend-vm
      - backend-vm
    routers:
      - frontend-router
      - backend-router
    subnets:
      - frontend-subnet
      - backend-subnet
    networks:
      - frontend-net
      - backend-net
    security_groups:
      - frontend-sg
      - backend-sg
  tasks:
    - name: Delete servers
      openstack.cloud.server:
        cloud: "{{ cloud }}"
        name: "{{ item }}"
        state: absent
        wait: yes
      loop: "{{ servers }}"

    - name: Remove routers
      loop: "{{ routers }}"
      openstack.cloud.router:
        cloud: "{{ cloud }}"
        name: "{{ item }}"
        state: absent

    - name: Delete subnets
      openstack.cloud.subnet:
        cloud: "{{ cloud }}"
        name: "{{ item }}"
        state: absent
      loop: "{{ subnets }}"

    - name: Delete networks
      openstack.cloud.network:
        cloud: "{{ cloud }}"
        name: "{{ item }}"
        state: absent
      loop: "{{ networks }}"

    - name: Delete security groups
      openstack.cloud.security_group:
        cloud: "{{ cloud }}"
        name: "{{ item }}"
        state: absent
      loop: "{{ security_groups }}"
```

### ▶️ Run Teardown

```bash
ansible-playbook -i inventory.ini teardown_multitier_app.yml
```

---

## ✅ Verification Steps for FIP, SSH, and HTTP

### 1. Floating IP Ping Test

After Exercise 4 is run, get the floating IP from output or via CLI:

```bash
openstack server show frontend-vm -f value -c addresses
```

Then test ping:

```bash
ping <floating_ip>
```

### 2. SSH Access

Ensure your key is available:

```bash
chmod 600 ~/.ssh/id_rsa
ssh -i ~/.ssh/id_rsa ubuntu@<floating_ip>
```

Use `centos@` for CentOS-based images.

### 3. HTTP Access (Optional if NGINX or Apache is pre-installed)

```bash
curl http://<floating_ip>
```

Or test via browser.

---

✅ You now have a full deployment, verification, and cleanup lifecycle for OpenStack multi-tier automation with Ansible!
