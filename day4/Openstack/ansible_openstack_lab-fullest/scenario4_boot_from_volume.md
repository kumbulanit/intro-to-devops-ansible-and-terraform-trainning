# Scenario 4 - Boot from Volume

## 🎯 Objective
Boot a VM using a volume created from an image with `boot_from_volume: true`.

## 🔧 Requirements
- OpenStack cloud running DevStack
- SSH key available
- Network (or volume) if required, already defined

## 📝 Steps

1. Open terminal and activate Ansible environment
2. Run the following command:
```bash
ansible-playbook -i inventory.ini scenario4_boot_from_volume.yml
```

## ✅ Validation
- Check for VM creation, network or volume attachment, or logs depending on the scenario.
- Use `openstack server list`, `openstack network list`, or `openstack volume list` as needed.

## 🧹 Teardown
```bash
ansible-playbook -i inventory.ini teardown_scenario4.yml
```
