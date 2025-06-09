# Scenario 9 - Role-Based Multi-VM Deployment

## 🎯 Objective
Deploy VMs using a reusable Ansible role and dynamic variables.

## 🔧 Requirements
- OpenStack cloud running DevStack
- SSH key available
- Network (or volume) if required, already defined

## 📝 Steps

1. Open terminal and activate Ansible environment
2. Run the following command:
```bash
ansible-playbook -i inventory.ini scenario9_role-based_multi-vm_deployment.yml
```

## ✅ Validation
- Check for VM creation, network or volume attachment, or logs depending on the scenario.
- Use `openstack server list`, `openstack network list`, or `openstack volume list` as needed.

## 🧹 Teardown
```bash
ansible-playbook -i inventory.ini teardown_scenario9.yml
```
