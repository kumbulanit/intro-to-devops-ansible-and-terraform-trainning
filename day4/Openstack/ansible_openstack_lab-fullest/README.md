# Ansible OpenStack Lab Kit

This lab kit is designed for a one-day training session to demonstrate Ansible automation of OpenStack DevStack resources.

## 📦 Contents

- 15 complete Ansible playbooks (scenario1 to scenario15)
- Inventory file (`inventory.ini`)
- Sample OpenStack cloud configuration (`clouds.yaml`)
- Lab guide (`lab_guide.md`)

## ⚙️ Prerequisites

- DevStack installed and running
- OpenStack image named `ubuntu` uploaded and active
- Public SSH key available at `~/.ssh/id_rsa.pub`
- Python packages:
```bash
sudo apt update && sudo apt install python3-pip -y
pip install openstacksdk ansible
```

- Create `~/.config/openstack/clouds.yaml`:
```yaml
clouds:
  devstack:
    region_name: RegionOne
    auth:
      auth_url: http://127.0.0.1/identity
      username: demo
      password: secret
      project_name: demo
      user_domain_name: Default
      project_domain_name: Default
    interface: public
    identity_api_version: 3
```

## ▶️ Running a Scenario

Example:
```bash
ansible-playbook -i inventory.ini scenario1_basic_vm.yml
```

For scenarios using secrets:
```bash
ansible-playbook -i inventory.ini scenario13_vaulted_vars.yml --ask-vault-pass
```

## 🧹 Teardown

Matching teardown playbooks are available as `teardown_scenarioX.yml`.

Example:
```bash
ansible-playbook -i inventory.ini teardown_scenario1.yml
```
