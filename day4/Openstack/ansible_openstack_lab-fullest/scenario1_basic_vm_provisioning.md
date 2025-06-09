# Scenario 1 - Basic VM Provisioning

## 🎯 Objective
Create a basic Ubuntu VM using default image and flavor. Inject an SSH key and verify connectivity.

## 🔧 Requirements
- OpenStack cloud running DevStack
- SSH key available
- Network (or volume) if required, already defined

## 📝 Steps

1. Open terminal and activate Ansible environment
2. Run the following command:
```bash
ansible-playbook -i inventory.ini scenario1_basic_vm_provisioning.yml
```

## ✅ Validation
- Check for VM creation, network or volume attachment, or logs depending on the scenario.
- Use `openstack server list`, `openstack network list`, or `openstack volume list` as needed.

## 🧹 Teardown
```bash
ansible-playbook -i inventory.ini teardown_scenario1.yml
```
