Here’s a full guide to:

⸻

🧪 1. Add Molecule Testing for the openstack_vm_infra Role

🔧 Prerequisites

Install dependencies:
```bash
pip install molecule[docker] ansible openstacksdk
sudo apt install docker.io
```
Create the Molecule scenario inside the role:
```bash
cd roles/openstack_vm_infra
molecule init scenario default -r openstack_vm_infra -d docker
```
Replace molecule/default/molecule.yml with this minimal Docker config:
```yaml
---
dependency:
name: galaxy
driver:
name: docker
platforms:
- name: instance
  image: ubuntu:22.04
  command: /sbin/init
  privileged: true
  pre_build_image: true
  provisioner:
  name: ansible
  log: true
  verifier:
  name: ansible
```
Update molecule/default/converge.yml to test the role:
```yaml
---
- name: Converge
  hosts: all
  tasks:
    - name: Include role
      include_role:
      name: openstack_vm_infra
```
Run the test:
```bash
cd roles/openstack_vm_infra
molecule test
```

⸻

📦 2. Set Up a Private Ansible Galaxy Repo on Localhost

You can simulate a Galaxy-like repo using a simple Git repo structure.

Step 1: Initialize a Git Repo
```bash
cd ~/ansible-galaxy-local
git init --bare openstack_vm_infra.git
```
Step 2: Push the Role

From your role directory:
```bash
cd roles/openstack_vm_infra
git init
git remote add origin ~/ansible-galaxy-local/openstack_vm_infra.git
git add .
git commit -m "Initial commit of OpenStack VM Infra role"
git push origin master
```

⸻

📘 3. Use the Role from Local Galaxy Repo (Private)

Add a requirements.yml:
```yaml
---
roles:
- name: openstack_vm_infra
  src: ~/ansible-galaxy-local/openstack_vm_infra.git
  scm: git
  version: master
```
Then install:
```bash
ansible-galaxy install -r requirements.yml --force
```

