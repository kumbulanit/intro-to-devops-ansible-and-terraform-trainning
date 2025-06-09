# Scenario 8 - Auto-Scaling Simulation

## 🎯 Objective
Simulate auto-scaling by launching multiple instances using loops.

## 🔧 Requirements
- OpenStack cloud running DevStack
- SSH key available
- Network (or volume) if required, already defined

## 📝 Steps

1. Open terminal and activate Ansible environment
2. Run the following command:
```bash
ansible-playbook -i inventory.ini scenario8_auto-scaling_simulation.yml
```

## ✅ Validation
- Check for VM creation, network or volume attachment, or logs depending on the scenario.
- Use `openstack server list`, `openstack network list`, or `openstack volume list` as needed.

## 🧹 Teardown
```bash
ansible-playbook -i inventory.ini teardown_scenario8.yml
```
