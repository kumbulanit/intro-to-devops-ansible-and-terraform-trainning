# Scenario 3 - Router and Gateway Setup

## 🎯 Objective
Configure a router and set the external gateway for external access.

## 🔧 Requirements
- OpenStack cloud running DevStack
- SSH key available
- Network (or volume) if required, already defined

## 📝 Steps

1. Open terminal and activate Ansible environment
2. Run the following command:
```bash
ansible-playbook -i inventory.ini scenario3_router_and_gateway_setup.yml
```

## ✅ Validation
- Check for VM creation, network or volume attachment, or logs depending on the scenario.
- Use `openstack server list`, `openstack network list`, or `openstack volume list` as needed.

## 🧹 Teardown
```bash
ansible-playbook -i inventory.ini teardown_scenario3.yml
```
