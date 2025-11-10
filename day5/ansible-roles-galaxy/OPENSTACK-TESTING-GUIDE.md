# 🌐 OpenStack Local Testing Guide for Ansible Roles

## Overview

This guide provides detailed instructions for testing all Day 5 Ansible roles using your local OpenStack instance from Day 4.

---

## 📋 Prerequisites Checklist

Before starting any lab, ensure you have:

### ✅ OpenStack Instance Ready

```bash
# 1. Verify OpenStack CLI is configured
openstack --version
# Expected: openstack 5.x.x or higher

# 2. Source your credentials
source ~/openstack-credentials.sh
# Or create if missing:
# export OS_AUTH_URL=http://your-controller:5000/v3
# export OS_PROJECT_NAME=your-project
# export OS_USERNAME=your-username
# export OS_PASSWORD=your-password
# export OS_USER_DOMAIN_NAME=Default
# export OS_PROJECT_DOMAIN_NAME=Default

# 3. Test OpenStack connection
openstack server list
openstack network list
openstack flavor list
openstack image list

# Expected: Lists should display without errors
```

### ✅ Ansible Control Machine Setup

```bash
# 1. Verify Ansible installation
ansible --version
# Expected: ansible [core 2.12+]

# 2. Check Python version
python3 --version
# Expected: Python 3.6 or higher

# 3. Install OpenStack collection (for advanced labs)
ansible-galaxy collection install openstack.cloud
pip3 install openstacksdk

# 4. Verify installation
ansible-galaxy collection list | grep openstack
```

### ✅ SSH Key Configuration

```bash
# 1. Check if you have SSH keys
ls -la ~/.ssh/

# 2. If not, create a keypair
ssh-keygen -t rsa -b 4096 -f ~/.ssh/openstack_key -N ""

# 3. Upload to OpenStack
openstack keypair create --public-key ~/.ssh/openstack_key.pub my-ansible-key

# 4. Verify keypair
openstack keypair list

# 5. Set correct permissions
chmod 600 ~/.ssh/openstack_key
chmod 644 ~/.ssh/openstack_key.pub
```

---

## 🚀 Quick Start: Setting Up Your Test Instance

### Option 1: Use Existing Instance from Day 4

```bash
# 1. Get your instance details
openstack server show YOUR_INSTANCE_NAME --format yaml > ~/my_instance.txt

# 2. Extract important information
INSTANCE_IP=$(openstack server show YOUR_INSTANCE_NAME -f value -c addresses | cut -d'=' -f2)
KEY_NAME=$(openstack server show YOUR_INSTANCE_NAME -f value -c key_name)

echo "Instance IP: $INSTANCE_IP"
echo "Key Name: $KEY_NAME"

# 3. Test SSH access
ssh -i ~/.ssh/openstack_key ubuntu@$INSTANCE_IP 'echo "SSH works!"'
```

### Option 2: Create New Test Instance

```bash
# 1. Choose an image (Ubuntu recommended)
openstack image list | grep -i ubuntu
IMAGE_ID="Ubuntu-22.04"  # or your preferred image

# 2. Choose a flavor
openstack flavor list
FLAVOR="m1.small"  # or appropriate size

# 3. Get your network
openstack network list
NETWORK="private"  # or your network name

# 4. Create security group for testing
openstack security group create ansible-testing \
  --description "Security group for Ansible role testing"

# 5. Add necessary rules
# SSH
openstack security group rule create \
  --protocol tcp --dst-port 22 \
  --remote-ip 0.0.0.0/0 \
  ansible-testing

# HTTP
openstack security group rule create \
  --protocol tcp --dst-port 80 \
  --remote-ip 0.0.0.0/0 \
  ansible-testing

# HTTPS
openstack security group rule create \
  --protocol tcp --dst-port 443 \
  --remote-ip 0.0.0.0/0 \
  ansible-testing

# PostgreSQL (for database labs)
openstack security group rule create \
  --protocol tcp --dst-port 5432 \
  --remote-ip 0.0.0.0/0 \
  ansible-testing

# HAProxy Stats (for load balancer labs)
openstack security group rule create \
  --protocol tcp --dst-port 8080 \
  --remote-ip 0.0.0.0/0 \
  ansible-testing

# ICMP (ping)
openstack security group rule create \
  --protocol icmp \
  --remote-ip 0.0.0.0/0 \
  ansible-testing

# 6. Launch instance
openstack server create \
  --image $IMAGE_ID \
  --flavor $FLAVOR \
  --network $NETWORK \
  --key-name my-ansible-key \
  --security-group ansible-testing \
  ansible-test-vm

# 7. Wait for instance to be ACTIVE
openstack server list | grep ansible-test-vm

# 8. Assign floating IP (if needed)
FLOATING_IP=$(openstack floating ip create public -f value -c floating_ip_address)
openstack server add floating ip ansible-test-vm $FLOATING_IP

echo "Your test instance is ready!"
echo "IP Address: $FLOATING_IP"
echo "Access: ssh -i ~/.ssh/openstack_key ubuntu@$FLOATING_IP"

# 9. Save details
cat > ~/ansible_test_instance.txt <<EOF
Instance Name: ansible-test-vm
Floating IP: $FLOATING_IP
Key File: ~/.ssh/openstack_key
User: ubuntu
Security Group: ansible-testing
EOF
```

---

## 📝 Standard Inventory Configuration

### Create Master Inventory File

```bash
# Create standard inventory for all labs
mkdir -p ~/ansible_training/day5/labs
cd ~/ansible_training/day5/labs

cat > inventory.ini <<'EOF'
[webservers]
openstack-vm ansible_host=REPLACE_WITH_YOUR_IP ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/openstack_key

[databases]
openstack-vm ansible_host=REPLACE_WITH_YOUR_IP ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/openstack_key

[loadbalancers]
openstack-vm ansible_host=REPLACE_WITH_YOUR_IP ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/openstack_key

[appservers]
openstack-vm ansible_host=REPLACE_WITH_YOUR_IP ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/openstack_key

[all:vars]
ansible_python_interpreter=/usr/bin/python3
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
EOF

# Replace IP address with your actual IP
sed -i "s/REPLACE_WITH_YOUR_IP/$FLOATING_IP/g" inventory.ini

# Or manually edit
nano inventory.ini
```

### Test Connectivity

```bash
# Test all groups
ansible all -i inventory.ini -m ping

# Expected output:
# openstack-vm | SUCCESS => {
#     "changed": false,
#     "ping": "pong"
# }

# Test specific group
ansible webservers -i inventory.ini -m ping

# Get system information
ansible all -i inventory.ini -m setup -a "filter=ansible_distribution*"
```

---

## 🧪 Testing Each Lab with OpenStack

### Lab 1: Nginx Basic Role

```bash
cd ~/ansible_training/day5/labs/roles/nginx-basic

# Ensure security group allows HTTP
openstack security group rule list ansible-testing | grep 80

# Run playbook
ansible-playbook ../../test-nginx-role.yml -i ../../inventory.ini -v

# Verify
curl http://$FLOATING_IP
firefox http://$FLOATING_IP  # or your browser
```

### Lab 2: Database Role

```bash
cd ~/ansible_training/day5/labs

# Ensure security group allows PostgreSQL
openstack security group rule list ansible-testing | grep 5432

# Run database playbook
ansible-playbook playbooks/02-database-basic.yml -i inventory.ini

# Verify from local machine
ansible databases -i inventory.ini -m shell \
  -a "sudo -u postgres psql -c '\l'" -b

# Or SSH and verify
ssh -i ~/.ssh/openstack_key ubuntu@$FLOATING_IP
sudo -u postgres psql
\l
\q
exit
```

### Lab 3: Complete Stack (Web + DB)

```bash
# Run complete stack
ansible-playbook playbooks/03-complete-stack.yml -i inventory.ini

# Verify web server
curl http://$FLOATING_IP

# Verify database
ansible all -i inventory.ini -m shell \
  -a "sudo systemctl status postgresql" -b

# Check connectivity between services
ansible all -i inventory.ini -m shell \
  -a "sudo netstat -tlnp | grep -E '(80|5432)'" -b
```

---

## 🔍 Troubleshooting Common Issues

### Issue 1: Cannot Connect to Instance

**Symptom:** `ansible all -m ping` fails with connection timeout

**Solutions:**

```bash
# 1. Check instance is running
openstack server show ansible-test-vm | grep status

# 2. Verify floating IP is assigned
openstack server show ansible-test-vm | grep addresses

# 3. Test SSH directly
ssh -i ~/.ssh/openstack_key -v ubuntu@$FLOATING_IP

# 4. Check security group
openstack security group rule list ansible-testing

# 5. Verify SSH key permissions
ls -la ~/.ssh/openstack_key
chmod 600 ~/.ssh/openstack_key

# 6. Try with different user (CentOS/RHEL uses 'centos', Debian uses 'admin')
ssh -i ~/.ssh/openstack_key centos@$FLOATING_IP
```

### Issue 2: Permission Denied (Publickey)

**Symptom:** SSH authentication fails

**Solutions:**

```bash
# 1. Verify correct key is being used
ssh -i ~/.ssh/openstack_key ubuntu@$FLOATING_IP

# 2. Check if keypair matches instance
openstack server show ansible-test-vm -f value -c key_name
openstack keypair list

# 3. Recreate instance with correct key if needed
openstack server delete ansible-test-vm
# Then recreate with --key-name flag

# 4. Use cloud-init to add your key (alternative)
cat > user_data.txt <<EOF
#cloud-config
users:
  - name: ubuntu
    ssh_authorized_keys:
      - $(cat ~/.ssh/openstack_key.pub)
EOF

openstack server create --user-data user_data.txt ...
```

### Issue 3: Port Not Accessible (HTTP/DB)

**Symptom:** curl or service connection fails

**Solutions:**

```bash
# 1. Check security group rules
openstack security group rule list ansible-testing

# 2. Add missing rule (example for HTTP)
openstack security group rule create \
  --protocol tcp --dst-port 80 \
  --remote-ip 0.0.0.0/0 \
  ansible-testing

# 3. Check service is running on instance
ansible all -i inventory.ini -m shell \
  -a "sudo systemctl status nginx" -b

# 4. Check firewall on instance (if enabled)
ansible all -i inventory.ini -m shell \
  -a "sudo ufw status" -b

# 5. Verify port is listening
ansible all -i inventory.ini -m shell \
  -a "sudo netstat -tlnp | grep 80" -b

# 6. Test from instance itself
ansible all -i inventory.ini -m shell \
  -a "curl localhost" -b
```

### Issue 4: Ansible Playbook Fails

**Symptom:** Tasks fail during execution

**Solutions:**

```bash
# 1. Run with maximum verbosity
ansible-playbook playbook.yml -i inventory.ini -vvvv

# 2. Check become (sudo) permissions
ansible all -i inventory.ini -m shell -a "sudo whoami" -b

# 3. Verify Python is installed
ansible all -i inventory.ini -m raw -a "which python3"

# 4. Check disk space
ansible all -i inventory.ini -m shell -a "df -h" -b

# 5. Check apt/yum lock (package installation issues)
ansible all -i inventory.ini -m shell \
  -a "sudo lsof /var/lib/dpkg/lock-frontend" -b

# 6. Run individual tasks
ansible all -i inventory.ini -m apt \
  -a "name=nginx state=present update_cache=yes" -b
```

### Issue 5: OpenStack Commands Not Working

**Symptom:** `openstack command not found` or authentication errors

**Solutions:**

```bash
# 1. Verify OpenStack client is installed
pip3 list | grep openstackclient
pip3 install python-openstackclient

# 2. Source credentials
source ~/openstack-credentials.sh

# 3. Verify authentication
openstack token issue

# 4. Check environment variables
env | grep OS_

# 5. Test with explicit auth
openstack --os-auth-url http://controller:5000/v3 \
  --os-project-name demo \
  --os-username demo \
  --os-password secret \
  server list
```

---

## 📊 Testing Workflow

### Standard Testing Process for Each Lab

```bash
# 1. PRE-TEST: Verify environment
ansible all -i inventory.ini -m ping
openstack server show ansible-test-vm

# 2. CHECK: Syntax validation
ansible-playbook playbook.yml -i inventory.ini --syntax-check

# 3. DRY RUN: See what would change
ansible-playbook playbook.yml -i inventory.ini --check

# 4. DEPLOY: Run playbook with logging
ansible-playbook playbook.yml -i inventory.ini -v | tee deployment.log

# 5. VERIFY: Test idempotency
ansible-playbook playbook.yml -i inventory.ini
# Should show changed=0

# 6. VALIDATE: Check services
ansible all -i inventory.ini -m shell \
  -a "sudo systemctl status SERVICE_NAME" -b

# 7. TEST: Functional testing
curl http://$FLOATING_IP
# Or specific service tests

# 8. CLEANUP (optional): Reset for next test
ansible all -i inventory.ini -m apt \
  -a "name=nginx state=absent purge=yes" -b
```

---

## 🎯 Quick Reference Commands

### OpenStack Management

```bash
# List all resources
openstack server list
openstack network list
openstack security group list
openstack floating ip list
openstack keypair list

# Get instance details
openstack server show INSTANCE_NAME

# Console log (for boot issues)
openstack console log show INSTANCE_NAME

# Reboot instance
openstack server reboot INSTANCE_NAME

# Delete and recreate
openstack server delete INSTANCE_NAME
# (see creation commands above)
```

### Ansible Testing

```bash
# Quick tests
ansible all -i inventory.ini -m ping
ansible all -i inventory.ini -m setup
ansible all -i inventory.ini -m shell -a "uptime" -b

# Service management
ansible all -i inventory.ini -m systemd \
  -a "name=nginx state=started enabled=yes" -b

# Package management
ansible all -i inventory.ini -m apt \
  -a "name=nginx state=present" -b

# File operations
ansible all -i inventory.ini -m copy \
  -a "content='test' dest=/tmp/test.txt" -b
```

### Debug and Information Gathering

```bash
# Get all facts
ansible all -i inventory.ini -m setup | less

# Specific facts
ansible all -i inventory.ini -m setup \
  -a "filter=ansible_default_ipv4"

# Disk usage
ansible all -i inventory.ini -m shell \
  -a "df -h" -b

# Memory info
ansible all -i inventory.ini -m shell \
  -a "free -h" -b

# Network connections
ansible all -i inventory.ini -m shell \
  -a "sudo netstat -tlnp" -b
```

---

## 💾 Snapshot and Restore

### Create Snapshot Before Testing

```bash
# Create snapshot
openstack server image create \
  --name "ansible-test-vm-snapshot-$(date +%Y%m%d)" \
  ansible-test-vm

# List snapshots
openstack image list | grep snapshot

# Restore from snapshot (if needed)
# 1. Delete current instance
openstack server delete ansible-test-vm

# 2. Create new instance from snapshot
openstack server create \
  --image ansible-test-vm-snapshot-DATE \
  --flavor m1.small \
  --network private \
  --key-name my-ansible-key \
  --security-group ansible-testing \
  ansible-test-vm
```

---

## 📚 Additional Resources

- **OpenStack Documentation**: https://docs.openstack.org/
- **Ansible Documentation**: https://docs.ansible.com/
- **OpenStack Ansible Collection**: https://docs.ansible.com/ansible/latest/collections/openstack/cloud/
- **Troubleshooting Guide**: See Day 4 materials

---

## ✅ Daily Testing Checklist

Before starting each lab session:

- [ ] OpenStack credentials sourced
- [ ] Test instance is running (`openstack server list`)
- [ ] Floating IP is assigned
- [ ] Security groups are configured
- [ ] SSH key permissions are correct (600)
- [ ] Ansible can ping the instance
- [ ] Required ports are open
- [ ] Snapshot created (for easy reset)

**Happy Testing! 🚀**
