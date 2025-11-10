# 📚 Day 5 Ansible Playbooks - Complete Installation Guide

## 📖 Overview

This directory contains production-ready Ansible playbooks for:
- **AWX Installation**: Local and OpenStack deployment
- **Three-Tier Application**: Complete infrastructure and application deployment
- **OpenStack Integration**: Automated infrastructure provisioning

---

## 📁 Playbook Index

### AWX Installation Playbooks

| Playbook | Description | Duration | Complexity |
|----------|-------------|----------|------------|
| `01-install-awx-local-docker-compose.yml` | Install AWX on local Ubuntu machine | 20-30 min | ⭐⭐ |
| `02-install-awx-openstack.yml` | Deploy AWX on OpenStack VM | 25-35 min | ⭐⭐⭐ |

### Three-Tier Application Playbooks

| Playbook | Description | Duration | Complexity |
|----------|-------------|----------|------------|
| `03-provision-three-tier-infrastructure.yml` | Provision OpenStack infrastructure (LB+Web+DB) | 5-10 min | ⭐⭐⭐ |
| `04-configure-database.yml` | Install and configure PostgreSQL | 3-5 min | ⭐⭐ |
| `05-configure-webservers.yml` | Install Nginx, PHP, deploy application | 5-7 min | ⭐⭐ |
| `06-configure-loadbalancer.yml` | Install and configure HAProxy | 3-5 min | ⭐⭐ |
| `07-deploy-complete-stack.yml` | **Master playbook - deploys everything** | 15-20 min | ⭐⭐⭐ |

---

## 🚀 Quick Start

### Option 1: Install AWX Locally

```bash
# Install AWX on your local Ubuntu machine
ansible-playbook 01-install-awx-local-docker-compose.yml

# Access AWX
open http://localhost:8080
# Username: admin
# Password: AWXAdminPassword123!
```

### Option 2: Install AWX on OpenStack

```bash
# Deploy AWX to OpenStack
ansible-playbook 02-install-awx-openstack.yml \
  -e "cloud_name=mycloud" \
  -e "openstack_key_name=my-keypair"

# Access AWX (check output for IP)
open http://AWX_PUBLIC_IP:8080
```

### Option 3: Deploy Three-Tier Application

```bash
# Deploy complete application stack
ansible-playbook 07-deploy-complete-stack.yml \
  -e "cloud_name=mycloud"

# Access application (check output for load balancer IP)
open http://LOAD_BALANCER_IP
```

---

## 📋 Prerequisites

### System Requirements

**For Local AWX Installation:**
- Ubuntu 20.04/22.04 or Debian 11+
- 8GB RAM (minimum 4GB)
- 4 CPU cores
- 20GB free disk space
- Sudo access

**For OpenStack Deployments:**
- OpenStack environment accessible
- `clouds.yaml` configured at `~/.config/openstack/clouds.yaml`
- SSH keypair created and imported to OpenStack
- Available quota:
  - For AWX: 1 VM (4 vCPUs, 8GB RAM), 1 Floating IP
  - For Three-Tier App: 4 VMs, 1 Floating IP minimum

### Software Prerequisites

```bash
# Install Ansible
sudo apt update
sudo apt install -y ansible python3-pip

# Install OpenStack SDK (for OpenStack playbooks)
pip3 install openstacksdk

# Install OpenStack Ansible collection
ansible-galaxy collection install openstack.cloud

# Verify installations
ansible --version
python3 -c "import openstack; print('OpenStack SDK installed')"
ansible-galaxy collection list | grep openstack
```

### Configure OpenStack (Required for OpenStack playbooks)

Create `~/.config/openstack/clouds.yaml`:

```yaml
clouds:
  mycloud:  # Your cloud name
    auth:
      auth_url: http://YOUR_OPENSTACK_IP/identity
      username: admin
      password: your_password
      project_name: admin
      project_domain_name: Default
      user_domain_name: Default
    region_name: RegionOne
    interface: public
    identity_api_version: 3
```

**Test connection:**

```bash
openstack --os-cloud=mycloud server list
```

---

## 📘 Detailed Usage Guide

### 1. AWX Installation on Local Machine

**Playbook:** `01-install-awx-local-docker-compose.yml`

**What it does:**
- Installs Docker and Docker Compose
- Deploys AWX using Docker containers
- Configures PostgreSQL database
- Sets up Redis cache
- Creates management scripts

**Usage:**

```bash
# Basic installation
ansible-playbook 01-install-awx-local-docker-compose.yml

# Custom admin password
ansible-playbook 01-install-awx-local-docker-compose.yml \
  -e "awx_admin_password=YourSecurePassword"

# Different AWX version
ansible-playbook 01-install-awx-local-docker-compose.yml \
  -e "awx_version=23.4.0"
```

**Access Information:**
- **URL:** http://localhost:8080
- **Username:** admin
- **Password:** (default: AWXAdminPassword123!)
- **Installation Dir:** /opt/awx

**Management Commands:**

```bash
# View running containers
docker ps

# View AWX logs
docker logs -f awx-web

# Restart AWX
cd /opt/awx && sudo docker-compose restart

# Stop AWX
cd /opt/awx && sudo docker-compose down

# Start AWX
cd /opt/awx && sudo docker-compose up -d
```

**Troubleshooting:**

```bash
# Check container status
docker ps -a

# View all logs
cd /opt/awx && sudo docker-compose logs

# Reset AWX (WARNING: Deletes all data)
cd /opt/awx && sudo docker-compose down -v
cd /opt/awx && sudo docker-compose up -d
```

---

### 2. AWX Installation on OpenStack

**Playbook:** `02-install-awx-openstack.yml`

**What it does:**
- Provisions OpenStack VM with proper sizing
- Creates security groups and rules
- Assigns floating IP
- Installs Docker and Docker Compose
- Deploys AWX
- Configures firewall (UFW)
- Creates management scripts

**Usage:**

```bash
# Basic deployment
ansible-playbook 02-install-awx-openstack.yml \
  -e "cloud_name=mycloud" \
  -e "openstack_key_name=my-keypair"

# Custom configuration
ansible-playbook 02-install-awx-openstack.yml \
  -e "cloud_name=mycloud" \
  -e "openstack_key_name=my-keypair" \
  -e "vm_name=awx-prod" \
  -e "vm_flavor=m1.xlarge" \
  -e "awx_admin_password=SecurePassword123!"
```

**Variables:**

| Variable | Default | Description |
|----------|---------|-------------|
| `cloud_name` | devstack | Cloud name from clouds.yaml |
| `vm_name` | awx-server | Name for the VM |
| `vm_flavor` | m1.large | OpenStack flavor (4 vCPU, 8GB RAM) |
| `vm_image` | ubuntu-22.04 | Base OS image |
| `openstack_key_name` | my-keypair | SSH keypair name |
| `awx_admin_password` | SecureAWXPassword123! | AWX admin password |

**Output Files:**
- `./awx-openstack-vm-info.txt` - VM connection details

**SSH Access:**

```bash
# Get VM IP from output
ssh ubuntu@AWX_PUBLIC_IP

# Management commands
sudo awx-manage.sh status
sudo awx-manage.sh logs
sudo awx-manage.sh restart
sudo awx-manage.sh backup
```

---

### 3. Three-Tier Application Deployment

#### 3a. Provision Infrastructure

**Playbook:** `03-provision-three-tier-infrastructure.yml`

**What it does:**
- Creates security groups with appropriate rules
- Provisions 4 VMs:
  - 1x Load Balancer (m1.small) with floating IP
  - 2x Web Servers (m1.medium)
  - 1x Database Server (m1.large)
- Generates dynamic inventory file
- Saves infrastructure information

**Usage:**

```bash
ansible-playbook 03-provision-three-tier-infrastructure.yml \
  -e "cloud_name=mycloud"
```

**Output Files:**
- `./inventories/production/hosts` - Ansible inventory
- `./infrastructure-info.txt` - Detailed VM information

#### 3b. Configure Database

**Playbook:** `04-configure-database.yml`

**What it does:**
- Installs PostgreSQL 14
- Configures network access
- Creates database and user
- Sets up sample schema
- Configures firewall

**Usage:**

```bash
ansible-playbook 04-configure-database.yml \
  -i inventories/production/hosts
```

**Verification:**

```bash
# SSH to database server
ssh ubuntu@DB_PRIVATE_IP

# Test database
sudo -u postgres psql -d webapp_db -c "SELECT * FROM visits;"
```

#### 3c. Configure Web Servers

**Playbook:** `05-configure-webservers.yml`

**What it does:**
- Installs Nginx and PHP
- Deploys PHP web application
- Configures health check endpoint
- Sets up firewall rules

**Usage:**

```bash
ansible-playbook 05-configure-webservers.yml \
  -i inventories/production/hosts
```

**Verification:**

```bash
# SSH to web server
ssh ubuntu@WEB_PRIVATE_IP

# Test locally
curl http://localhost/health
```

#### 3d. Configure Load Balancer

**Playbook:** `06-configure-loadbalancer.yml`

**What it does:**
- Installs HAProxy
- Configures load balancing with health checks
- Sets up statistics page
- Creates management scripts
- Configures firewall

**Usage:**

```bash
ansible-playbook 06-configure-loadbalancer.yml \
  -i inventories/production/hosts
```

**Access:**
- **Application:** http://LOAD_BALANCER_IP
- **HAProxy Stats:** http://LOAD_BALANCER_IP:8404/stats
  - Username: admin
  - Password: HAProxyStatsPassword123!

#### 3e. Deploy Complete Stack (Recommended)

**Playbook:** `07-deploy-complete-stack.yml`

**What it does:**
- Runs all playbooks in sequence
- Provisions infrastructure
- Configures all tiers
- Performs final verification
- Displays comprehensive summary

**Usage:**

```bash
# Deploy everything at once
ansible-playbook 07-deploy-complete-stack.yml \
  -e "cloud_name=mycloud"

# This is equivalent to running:
# 1. 03-provision-three-tier-infrastructure.yml
# 2. 04-configure-database.yml
# 3. 05-configure-webservers.yml
# 4. 06-configure-loadbalancer.yml
```

**Timeline:**
1. Infrastructure provisioning: 5-10 minutes
2. Database configuration: 3-5 minutes
3. Web servers configuration: 5-7 minutes
4. Load balancer configuration: 3-5 minutes
5. **Total:** ~15-20 minutes

---

## 🎯 Common Use Cases

### Use Case 1: Quick AWX Demo

```bash
# Install locally for testing
ansible-playbook 01-install-awx-local-docker-compose.yml

# Takes 20-30 minutes
# Access at http://localhost:8080
```

### Use Case 2: Production AWX Deployment

```bash
# Deploy to OpenStack for production use
ansible-playbook 02-install-awx-openstack.yml \
  -e "cloud_name=production" \
  -e "openstack_key_name=prod-keypair" \
  -e "vm_flavor=m1.xlarge" \
  -e "awx_admin_password=$(openssl rand -base64 32)"

# Save password securely!
```

### Use Case 3: Development Environment

```bash
# Deploy three-tier app for development
ansible-playbook 07-deploy-complete-stack.yml \
  -e "cloud_name=dev-cloud"

# Test changes, iterate quickly
```

### Use Case 4: Production Application Deployment

```bash
# Deploy production-ready three-tier app
ansible-playbook 07-deploy-complete-stack.yml \
  -e "cloud_name=production" \
  -e "key_name=prod-keypair"

# Add SSL/TLS, monitoring, backups separately
```

### Use Case 5: Update Only Web Tier

```bash
# Update web servers without touching DB or LB
ansible-playbook 05-configure-webservers.yml \
  -i inventories/production/hosts
```

---

## 🔧 Customization

### Modify AWX Configuration

Edit variables in the playbook:

```yaml
vars:
  awx_version: "23.5.0"              # Change AWX version
  awx_admin_password: "YourPass"     # Set admin password
  awx_install_dir: /opt/awx          # Change install location
  postgres_password: "DBPass"        # Database password
```

### Modify Application Configuration

**Database credentials:**

```yaml
# In 04-configure-database.yml
vars:
  db_name: webapp_db
  db_user: webapp_user
  db_password: "YourSecurePassword"
```

**Application settings:**

```yaml
# In 05-configure-webservers.yml
vars:
  app_port: 80
  db_host: "{{ hostvars[groups['databases'][0]]['ansible_host'] }}"
  app_dir: /var/www/webapp
```

**Load balancer algorithm:**

```haproxy
# In 06-configure-loadbalancer.yml
# Change from roundrobin to:
balance leastconn  # Least connections
balance source     # Source IP hash
```

---

## 🛠️ Troubleshooting

### AWX Installation Issues

**Problem:** Docker containers not starting

```bash
# Check logs
docker logs awx-web
docker logs awx-postgres

# Check resources
free -h
df -h

# Restart services
cd /opt/awx && sudo docker-compose restart
```

**Problem:** Cannot access AWX web interface

```bash
# Check if container is running
docker ps | grep awx

# Check port binding
netstat -tuln | grep 8080

# Check firewall
sudo ufw status
sudo ufw allow 8080/tcp
```

### OpenStack Issues

**Problem:** Cannot connect to OpenStack

```bash
# Test clouds.yaml
openstack --os-cloud=mycloud server list

# Check credentials
cat ~/.config/openstack/clouds.yaml

# Verify network connectivity
ping YOUR_OPENSTACK_IP
```

**Problem:** Insufficient quota

```bash
# Check current quota
openstack quota show

# List current usage
openstack server list
openstack floating ip list
```

### Application Issues

**Problem:** Web application not connecting to database

```bash
# Check database is listening
ansible databases -i inventories/production/hosts \
  -b -a "netstat -tuln | grep 5432"

# Test connection from web server
ansible webservers -i inventories/production/hosts \
  -b -a "nc -zv DB_IP 5432"

# Check PostgreSQL logs
ansible databases -i inventories/production/hosts \
  -b -a "tail -n 50 /var/log/postgresql/postgresql-14-main.log"
```

**Problem:** Load balancer not distributing traffic

```bash
# Check HAProxy status
ansible loadbalancers -i inventories/production/hosts \
  -b -a "systemctl status haproxy"

# View backend status
ssh ubuntu@LB_IP "echo 'show stat' | sudo socat /run/haproxy/admin.sock stdio"

# Check HAProxy logs
ansible loadbalancers -i inventories/production/hosts \
  -b -a "journalctl -u haproxy -n 100"
```

---

## 📊 Verification Checklist

### AWX Installation

- [ ] All Docker containers running (`docker ps`)
- [ ] Can access web interface (http://localhost:8080 or http://PUBLIC_IP:8080)
- [ ] Can login with admin credentials
- [ ] API responds (`curl http://localhost:8080/api/v2/ping/`)

### Three-Tier Application

- [ ] All VMs provisioned and running
- [ ] Can SSH to all servers
- [ ] Database accepting connections
- [ ] Web servers responding to health checks
- [ ] Load balancer distributing traffic
- [ ] Application accessible via load balancer IP
- [ ] Page refresh shows different server names (load balancing working)
- [ ] HAProxy stats page accessible

---

## 🔐 Security Best Practices

### For Production Deployments

1. **Use Ansible Vault for Passwords:**

```bash
# Create encrypted variables file
ansible-vault create group_vars/all/vault.yml

# Add passwords
vault_awx_admin_password: SecurePassword123!
vault_db_password: DatabasePassword123!

# Use in playbooks
ansible-playbook 02-install-awx-openstack.yml \
  --ask-vault-pass \
  -e "awx_admin_password={{ vault_awx_admin_password }}"
```

2. **Restrict Security Group Rules:**

```yaml
# Instead of 0.0.0.0/0, use specific IPs
- { protocol: tcp, port: 22, cidr: 'YOUR_IP/32' }
```

3. **Change Default Passwords:**

All default passwords should be changed in production!

4. **Enable HTTPS:**

Configure SSL/TLS certificates for AWX and load balancer.

5. **Regular Backups:**

```bash
# AWX backup
sudo awx-manage.sh backup

# Database backup
ansible databases -i inventories/production/hosts \
  -b -a "sudo -u postgres pg_dump webapp_db > /backup/db-$(date +%Y%m%d).sql"
```

---

## 📚 Additional Resources

### Documentation
- [Ansible Documentation](https://docs.ansible.com/)
- [AWX Documentation](https://github.com/ansible/awx)
- [OpenStack Ansible Modules](https://docs.openstack.org/ansible-collections-openstack/latest/)
- [HAProxy Documentation](http://www.haproxy.org/)

### Related Playbooks
- Day 1-4 training materials in parent directories
- AWX/Jenkins integration guides in `../ansible-tower-awx/`

---

## 🎉 Success Indicators

Your deployment is successful when:

### AWX
- ✅ Web interface loads without errors
- ✅ Can create organizations, projects, and job templates
- ✅ Can run ad-hoc commands
- ✅ All containers healthy (`docker ps`)

### Three-Tier Application
- ✅ Load balancer IP accessible from browser
- ✅ Page displays server information and database connection status
- ✅ Page refresh shows different server names (load balancing)
- ✅ Visit counter increments (database working)
- ✅ HAProxy stats show all backends UP

---

## 🆘 Getting Help

If you encounter issues:

1. **Check playbook output** for error messages
2. **Review log files** on target servers
3. **Verify prerequisites** are met
4. **Test connectivity** between components
5. **Consult troubleshooting section** above

Common log locations:
- AWX: `docker logs awx-web`
- Nginx: `/var/log/nginx/error.log`
- PostgreSQL: `/var/log/postgresql/postgresql-14-main.log`
- HAProxy: `journalctl -u haproxy`

---

**Happy Automating! 🚀**

For questions or improvements, please refer to the main Day 5 README or training materials.
