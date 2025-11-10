# 🚀 Single Instance Deployment Guide

## 📖 Overview

This guide shows you how to deploy **everything on a single existing OpenStack instance**:
- AWX (Ansible Tower)
- PostgreSQL Database
- Nginx Web Server with PHP
- HAProxy Load Balancer
- Sample Three-Tier Application

**Perfect for**: Testing, demos, learning, or development environments.

---

## 🎯 What You'll Deploy

```
┌─────────────────────────────────────────────────────────────┐
│           Single OpenStack Instance                         │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  🐳 Docker Containers:                                       │
│     └─ AWX (Port 8080)                                       │
│        ├─ awx-web                                            │
│        ├─ awx-postgres                                       │
│        └─ awx-redis                                          │
│                                                               │
│  📊 System Services:                                         │
│     ├─ HAProxy Load Balancer (Port 80)                      │
│     ├─ Nginx Web Server (Port 8081)                         │
│     ├─ PHP-FPM Application                                  │
│     └─ PostgreSQL Database (Port 5432)                      │
│                                                               │
│  Traffic Flow:                                               │
│     Client → HAProxy:80 → Nginx:8081 → PHP → PostgreSQL     │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

---

## ⚡ Quick Start (3 Steps)

### Step 1: Update Inventory

Edit `inventory.ini` with your OpenStack instance details:

```bash
vim inventory.ini
```

Replace `YOUR_OPENSTACK_IP` with your actual IP:

```ini
[openstack_instance]
openstack-server ansible_host=YOUR_OPENSTACK_IP ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_rsa
```

**Example:**
```ini
[openstack_instance]
openstack-server ansible_host=192.168.1.100 ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/my-key.pem
```

### Step 2: Test Connection

```bash
ansible -i inventory.ini openstack_instance -m ping
```

Expected output:
```
openstack-server | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

### Step 3: Deploy Everything

```bash
ansible-playbook 10-deploy-everything-single-instance.yml -i inventory.ini
```

⏱️ **Time:** 40-50 minutes

☕ Grab a coffee! The playbook will:
1. Check system requirements
2. Install AWX (20-30 minutes)
3. Install application stack (10-15 minutes)
4. Verify all services
5. Display access information

---

## 📋 Prerequisites

### Your OpenStack Instance Must Have:

| Requirement | Minimum | Recommended |
|-------------|---------|-------------|
| **CPU** | 4 cores | 8 cores |
| **RAM** | 8GB | 16GB |
| **Disk** | 40GB | 80GB |
| **OS** | Ubuntu 20.04/22.04 | Ubuntu 22.04 |
| **Network** | Internet access | High-speed connection |

### Your Local Machine Must Have:

```bash
# Install Ansible
sudo apt update && sudo apt install -y ansible

# Verify installation
ansible --version
```

### SSH Access:

```bash
# Test SSH connection
ssh -i ~/.ssh/your-key.pem ubuntu@YOUR_OPENSTACK_IP

# If successful, you should see the Ubuntu prompt
ubuntu@instance:~$
```

---

## 🎮 Step-by-Step Instructions

### 1. Clone or Navigate to Playbooks Directory

```bash
cd /path/to/day5/playbooks/
```

### 2. Configure Inventory File

```bash
# Edit the inventory
vim inventory.ini

# Update these values:
# - YOUR_OPENSTACK_IP: Your instance's public IP
# - ansible_ssh_private_key_file: Path to your SSH key
# - Passwords (optional, or keep defaults)
```

### 3. Verify Prerequisites

```bash
# Check connectivity
ansible -i inventory.ini openstack_instance -m ping

# Check sudo access
ansible -i inventory.ini openstack_instance -b -m shell -a "whoami"
# Should return: root

# Check system resources
ansible -i inventory.ini openstack_instance -m setup -a "filter=ansible_memory_mb"
```

### 4. Run Deployment

```bash
# Deploy everything
ansible-playbook 10-deploy-everything-single-instance.yml -i inventory.ini

# Watch the magic happen! 🎩✨
```

### 5. Monitor Progress

The playbook shows real-time progress:

```
╔════════════════════════════════════════════════════════════════╗
║   Complete Deployment on Single OpenStack Instance            ║
╚════════════════════════════════════════════════════════════════╝

📍 Target Server: openstack-server
🌐 IP Address: 192.168.1.100
...

STAGE 1/2: Installing AWX (Ansible Tower)
⏱️  This will take approximately 20-30 minutes...
[Progress updates...]

STAGE 2/2: Installing Application Stack
⏱️  This will take approximately 10-15 minutes...
[Progress updates...]

╔════════════════════════════════════════════════════════════════╗
║          🎉 DEPLOYMENT COMPLETED SUCCESSFULLY! 🎉             ║
╚════════════════════════════════════════════════════════════════╝
```

---

## 🌐 Access Your Deployment

After successful deployment, you'll have:

### AWX (Ansible Tower)
- **URL:** http://YOUR_IP:8080
- **Username:** `admin`
- **Password:** `AWXAdminPassword123!` (or from inventory)

### Web Application
- **URL:** http://YOUR_IP
- Displays server info and database connectivity

### HAProxy Statistics
- **URL:** http://YOUR_IP:8404/stats
- **Username:** `admin`
- **Password:** `HAProxyStatsPassword123!` (or from inventory)

### Direct Web Access (Bypass Load Balancer)
- **URL:** http://YOUR_IP:8081

---

## 🔧 Playbook Details

### Available Playbooks

| Playbook | Description | Use When |
|----------|-------------|----------|
| `10-deploy-everything-single-instance.yml` | **⭐ Recommended** - Deploys everything | Fresh installation |
| `08-install-awx-on-existing-instance.yml` | Installs only AWX | Already have apps, need AWX |
| `09-install-all-apps-on-single-instance.yml` | Installs only apps (no AWX) | Already have AWX, need apps |
| `inventory.ini` | Configuration file | Always update first! |

### Individual Installation Options

**Install only AWX:**
```bash
ansible-playbook 08-install-awx-on-existing-instance.yml -i inventory.ini
```

**Install only applications (without AWX):**
```bash
ansible-playbook 09-install-all-apps-on-single-instance.yml -i inventory.ini
```

**Install everything (recommended):**
```bash
ansible-playbook 10-deploy-everything-single-instance.yml -i inventory.ini
```

---

## 🎨 Customization

### Change Passwords

Edit `inventory.ini` before deployment:

```ini
[awx_servers:vars]
awx_admin_password=MySecurePassword123!

[database_servers:vars]
db_password=MyDBPassword123!

[load_balancers:vars]
haproxy_stats_password=MyStatsPassword123!
```

### Change Ports

Edit `inventory.ini`:

```ini
[awx_servers:vars]
awx_host_port=8080  # Change AWX port

[web_servers:vars]
app_port=8081  # Change web server port

[load_balancers:vars]
lb_frontend_port=80  # Change load balancer port
haproxy_stats_port=8404  # Change stats port
```

### Change Database Name

```ini
[database_servers:vars]
db_name=my_custom_db
db_user=my_custom_user
```

---

## 🔍 Verification

### Check All Services

```bash
# SSH to your instance
ssh -i ~/.ssh/your-key.pem ubuntu@YOUR_IP

# Check all services
sudo systemctl status docker postgresql nginx haproxy

# Check Docker containers
docker ps

# Should see:
# - awx-web
# - awx-postgres
# - awx-redis
```

### Test Each Component

```bash
# Test AWX
curl http://localhost:8080/api/v2/ping/
# Should return: {"ha":false,"version":"24.3.1",...}

# Test Web Server
curl http://localhost:8081/health
# Should return: {"status":"healthy",...}

# Test Load Balancer
curl http://localhost:80/
# Should return: HTML page

# Test Database
sudo -u postgres psql -d webapp_db -c "SELECT COUNT(*) FROM visits;"
# Should return: count number
```

---

## 🛠️ Management

### Service Management

```bash
# SSH to your instance first
ssh -i ~/.ssh/your-key.pem ubuntu@YOUR_IP

# Check status
sudo systemctl status docker
sudo systemctl status postgresql
sudo systemctl status nginx
sudo systemctl status haproxy

# Restart services
sudo systemctl restart postgresql
sudo systemctl restart nginx
sudo systemctl restart haproxy

# Manage AWX
sudo awx-manage.sh status
sudo awx-manage.sh restart
sudo awx-manage.sh logs
```

### View Logs

```bash
# AWX logs
docker logs -f awx-web
docker logs -f awx-postgres

# Nginx logs
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log

# HAProxy logs
sudo journalctl -u haproxy -f

# PostgreSQL logs
sudo tail -f /var/log/postgresql/postgresql-14-main.log
```

### AWX Management Script

```bash
# Start AWX
sudo awx-manage.sh start

# Stop AWX
sudo awx-manage.sh stop

# Restart AWX
sudo awx-manage.sh restart

# View status
sudo awx-manage.sh status

# View logs
sudo awx-manage.sh logs

# Create backup
sudo awx-manage.sh backup
```

---

## 🚨 Troubleshooting

### Problem: Cannot Connect to Instance

```bash
# Check if instance is reachable
ping YOUR_IP

# Check SSH
ssh -v -i ~/.ssh/your-key.pem ubuntu@YOUR_IP

# Check security groups (allow ports 22, 80, 8080, 8081, 8404)
```

### Problem: Playbook Fails at AWX Installation

```bash
# SSH to instance
ssh -i ~/.ssh/your-key.pem ubuntu@YOUR_IP

# Check Docker
sudo docker --version
sudo systemctl status docker

# Check disk space
df -h

# Check memory
free -h

# If Docker containers failed:
cd /opt/awx
sudo docker-compose down
sudo docker-compose up -d
```

### Problem: AWX Not Accessible

```bash
# Check containers
docker ps -a

# Check AWX logs
docker logs awx-web

# Restart AWX
sudo awx-manage.sh restart

# Check firewall
sudo ufw status
sudo ufw allow 8080/tcp
```

### Problem: Web Application Not Working

```bash
# Check Nginx
sudo systemctl status nginx
sudo nginx -t

# Check PHP
php -v

# Check application logs
sudo tail -f /var/log/nginx/error.log

# Restart Nginx
sudo systemctl restart nginx
```

### Problem: Database Connection Error

```bash
# Check PostgreSQL
sudo systemctl status postgresql

# Test connection
sudo -u postgres psql -d webapp_db -c "SELECT 1;"

# Check PostgreSQL logs
sudo tail -f /var/log/postgresql/postgresql-14-main.log

# Restart PostgreSQL
sudo systemctl restart postgresql
```

### Problem: Load Balancer Not Working

```bash
# Check HAProxy
sudo systemctl status haproxy

# Test configuration
sudo haproxy -c -f /etc/haproxy/haproxy.cfg

# View HAProxy stats
# Open: http://YOUR_IP:8404/stats

# Restart HAProxy
sudo systemctl restart haproxy
```

---

## 📊 Port Reference

| Port | Service | Access |
|------|---------|--------|
| 22 | SSH | Remote management |
| 80 | HAProxy Frontend | Main application access |
| 5432 | PostgreSQL | Database (internal) |
| 8080 | AWX | Ansible Tower web interface |
| 8081 | Nginx | Direct web server access |
| 8404 | HAProxy Stats | Load balancer statistics |

---

## 🔐 Security Considerations

### For Production Use:

1. **Change all default passwords** in `inventory.ini`
2. **Use Ansible Vault** for sensitive data:
   ```bash
   ansible-vault encrypt_string 'MyPassword' --name 'awx_admin_password'
   ```
3. **Restrict firewall rules**:
   ```bash
   # Allow only specific IPs
   sudo ufw delete allow 8080/tcp
   sudo ufw allow from YOUR_IP to any port 8080
   ```
4. **Enable HTTPS** with Let's Encrypt
5. **Regular backups**:
   ```bash
   sudo awx-manage.sh backup
   ```

---

## 📚 What Gets Installed

### Docker Containers (for AWX):
- `awx-web` - AWX web interface
- `awx-postgres` - AWX database
- `awx-redis` - AWX cache

### System Services:
- **Docker** - Container runtime
- **Docker Compose** - Container orchestration
- **PostgreSQL** - Database server (for web app)
- **Nginx** - Web server
- **PHP-FPM** - PHP processor
- **HAProxy** - Load balancer

### Management Tools:
- `/usr/local/bin/awx-manage.sh` - AWX management script
- Various configuration files
- Sample web application

---

## 🎓 Learning Outcomes

After completing this deployment, you'll understand:

✅ How to deploy AWX using Docker  
✅ How to configure a three-tier application  
✅ Load balancing with HAProxy  
✅ Web server configuration with Nginx  
✅ Database management with PostgreSQL  
✅ Service orchestration with Ansible  
✅ Security group and firewall configuration  

---

## 📁 Generated Files

After deployment, you'll find these files locally:

```
./awx-access-info.txt                    # AWX credentials and info
./complete-stack-access-info.txt         # Full stack access details
./deployment-summary-YYYY-MM-DD.txt      # Complete deployment summary
```

---

## 🔄 Update or Reinstall

### To Update Application:

```bash
# Re-run application playbook
ansible-playbook 09-install-all-apps-on-single-instance.yml -i inventory.ini
```

### To Reinstall AWX:

```bash
# SSH to instance
ssh -i ~/.ssh/your-key.pem ubuntu@YOUR_IP

# Remove AWX
cd /opt/awx
sudo docker-compose down -v
sudo rm -rf /opt/awx

# Re-run AWX playbook
ansible-playbook 08-install-awx-on-existing-instance.yml -i inventory.ini
```

### To Reinstall Everything:

```bash
# SSH to instance and remove everything
ssh -i ~/.ssh/your-key.pem ubuntu@YOUR_IP

# Stop all services
sudo systemctl stop haproxy nginx postgresql
cd /opt/awx && sudo docker-compose down -v

# Remove packages (optional)
sudo apt remove --purge -y haproxy nginx postgresql*

# Re-run complete deployment
ansible-playbook 10-deploy-everything-single-instance.yml -i inventory.ini
```

---

## 💡 Tips and Tricks

### Faster Deployment:
- Use an instance with faster internet
- Increase CPU/RAM for faster Docker builds
- Pre-download Docker images

### Monitor Deployment:
```bash
# In another terminal, SSH and watch logs
ssh -i ~/.ssh/your-key.pem ubuntu@YOUR_IP
tail -f /var/log/syslog
```

### Test Before Deploying:
```bash
# Dry run (check mode)
ansible-playbook 10-deploy-everything-single-instance.yml -i inventory.ini --check

# Run only on specific hosts
ansible-playbook 10-deploy-everything-single-instance.yml -i inventory.ini --limit openstack-server
```

---

## 🆘 Getting Help

### Check Logs:
```bash
# View playbook output
ansible-playbook ... | tee deployment.log

# Check system logs on instance
ssh ubuntu@YOUR_IP
sudo journalctl -xe
```

### Verify Configuration:
```bash
# Test inventory
ansible-inventory -i inventory.ini --list

# Test playbook syntax
ansible-playbook 10-deploy-everything-single-instance.yml --syntax-check
```

### Common Commands Reference:
```bash
# Check what will change (dry run)
ansible-playbook playbook.yml -i inventory.ini --check --diff

# Run with verbose output
ansible-playbook playbook.yml -i inventory.ini -vvv

# Run specific tasks (tags)
ansible-playbook playbook.yml -i inventory.ini --tags "docker,awx"
```

---

## 🎯 Next Steps

After successful deployment:

1. **Configure AWX:**
   - Add your inventory
   - Create credentials
   - Import projects from Git
   - Create job templates

2. **Customize Web Application:**
   - Modify PHP code in `/var/www/webapp/`
   - Update Nginx configuration
   - Add your own application

3. **Production Hardening:**
   - Enable HTTPS
   - Configure backups
   - Set up monitoring
   - Implement log rotation

4. **Scale Up:**
   - Add more web servers
   - Use external PostgreSQL
   - Implement caching
   - Add monitoring tools

---

## ✅ Success Checklist

- [ ] Updated `inventory.ini` with your instance IP
- [ ] Tested SSH connection to instance
- [ ] Verified instance meets requirements (8GB RAM, 4 CPUs)
- [ ] Ran deployment playbook successfully
- [ ] Can access AWX at http://YOUR_IP:8080
- [ ] Can access web app at http://YOUR_IP
- [ ] Can access HAProxy stats at http://YOUR_IP:8404/stats
- [ ] All health checks passed
- [ ] Saved access credentials securely

---

**🎉 Congratulations! You've successfully deployed a complete Ansible AWX and three-tier application stack on a single OpenStack instance!**

For the original multi-VM deployment, see the main [README.md](README.md).
