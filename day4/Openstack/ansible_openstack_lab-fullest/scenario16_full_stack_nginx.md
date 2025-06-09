# Scenario 16 - Full Stack NGINX VM Deployment

## 🎯 Objective
Provision a full working VM with a custom network, router, subnet, and install NGINX using cloud-init. All components are verified at each stage.

## 🔧 Requirements
- DevStack up and running
- Public image `ubuntu` available
- External network configured as `public`
- Your SSH public key located at `~/.ssh/id_rsa.pub`

## 📝 Steps

1. Review and adjust default variables in `roles/full_stack_nginx/defaults/main.yml` if needed.
2. Run the deployment playbook:
```bash
ansible-playbook -i inventory.ini playbooks/full_stack_nginx.yml
```

## ✅ Verifications

- Use `openstack server list` to verify instance creation
- Use `openstack network list`, `subnet list`, `router list` to confirm networking
- Use a browser or `curl` to access the public IP:
```bash
curl http://<public_ip>
```

## 🧹 Teardown
To delete all created resources manually, use:
```bash
openstack server delete nginx-vm
openstack router remove subnet nginx-router nginx-subnet
openstack router delete nginx-router
openstack subnet delete nginx-subnet
openstack network delete nginx-net
openstack security group delete nginx-secgroup
```

Or you can automate teardown later by creating `teardown_scenario16.yml`.
