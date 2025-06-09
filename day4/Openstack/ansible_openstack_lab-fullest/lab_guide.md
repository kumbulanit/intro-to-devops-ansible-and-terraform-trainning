# Ansible OpenStack Lab Guide - One Day Course

## 🧰 Prerequisites
- DevStack installed and running
- Ubuntu image uploaded and active in OpenStack
- Public SSH key present at `~/.ssh/id_rsa.pub`
- OpenStack credentials in `~/.config/openstack/clouds.yaml`
- Ansible inventory file with localhost:
```
[local]
localhost ansible_connection=local
```
- Required packages:
```bash
sudo apt update && sudo apt install python3-pip -y
pip install openstacksdk ansible
```

## ▶️ Running the Labs
Run any playbook like:
```bash
ansible-playbook -i inventory.ini scenario1_basic_vm.yml
```

## ✅ Scenarios
### Scenario 1 - Basic VM Provisioning
- Provisions a VM with Ubuntu image
- Injects SSH key
- Waits for SSH availability

### Scenario 2 - Create Network and Subnet
- Creates internal tenant network
- Sets up subnet with DHCP and DNS

(more scenarios to be added...)
