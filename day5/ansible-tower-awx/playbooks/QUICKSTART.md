# ⚡ Quick Start Guide - Single Instance Deployment

## 🎯 For Your Existing OpenStack Instance

**Goal:** Install AWX + Complete Application Stack on your OpenStack machine.

---

## 📝 Prerequisites Checklist

- [ ] OpenStack instance running (Ubuntu 20.04/22.04)
- [ ] Instance has: 8GB RAM, 4 CPUs, 40GB disk
- [ ] You have SSH access with sudo privileges
- [ ] Ansible installed on your local machine

---

## 🚀 Three Simple Steps

### 1️⃣ Edit Inventory (2 minutes)

```bash
cd day5/playbooks/
vim inventory.ini
```

**Change this line:**
```ini
openstack-server ansible_host=YOUR_OPENSTACK_IP
```

**To your actual IP:**
```ini
openstack-server ansible_host=192.168.1.100
```

**Also update your SSH key path if needed:**
```ini
ansible_ssh_private_key_file=~/.ssh/your-key.pem
```

### 2️⃣ Test Connection (30 seconds)

```bash
ansible -i inventory.ini openstack_instance -m ping
```

✅ **Should see:** `SUCCESS` and `"ping": "pong"`

### 3️⃣ Deploy Everything (40-50 minutes)

```bash
ansible-playbook 10-deploy-everything-single-instance.yml -i inventory.ini
```

☕ **Go grab a coffee!** The playbook handles everything automatically.

---

## 🌐 After Deployment

### Access Your Services:

| Service | URL | Credentials |
|---------|-----|-------------|
| **AWX** | http://YOUR_IP:8080 | admin / AWXAdminPassword123! |
| **Web App** | http://YOUR_IP | (no login needed) |
| **HAProxy Stats** | http://YOUR_IP:8404/stats | admin / HAProxyStatsPassword123! |

Replace `YOUR_IP` with your OpenStack instance IP address.

---

## 🔍 Verify Installation

```bash
# SSH to your instance
ssh -i ~/.ssh/your-key.pem ubuntu@YOUR_IP

# Check all services are running
sudo systemctl status docker postgresql nginx haproxy

# Check Docker containers
docker ps
# Should see: awx-web, awx-postgres, awx-redis

# Check AWX
curl http://localhost:8080/api/v2/ping/
```

---

## 🛠️ Common Commands

```bash
# Restart a service
sudo systemctl restart nginx
sudo systemctl restart haproxy

# View logs
docker logs -f awx-web
sudo journalctl -u nginx -f
sudo journalctl -u haproxy -f

# Manage AWX
sudo awx-manage.sh status
sudo awx-manage.sh restart
sudo awx-manage.sh logs
```

---

## 🚨 Troubleshooting

### Problem: Connection refused when testing ping

```bash
# Check SSH key permissions
chmod 600 ~/.ssh/your-key.pem

# Test SSH manually
ssh -i ~/.ssh/your-key.pem ubuntu@YOUR_IP

# Check security groups allow SSH (port 22)
```

### Problem: Playbook fails with "insufficient memory"

```bash
# Check your instance size
ssh ubuntu@YOUR_IP
free -h
# Need at least 8GB RAM

# Upgrade your instance if needed
```

### Problem: AWX not accessible after installation

```bash
# SSH to instance
ssh -i ~/.ssh/your-key.pem ubuntu@YOUR_IP

# Check containers
docker ps -a

# Restart AWX
sudo awx-manage.sh restart

# Check logs
docker logs awx-web
```

---

## 📊 What Gets Installed

```
Your OpenStack Instance:
├── Docker + Docker Compose
├── AWX (Ansible Tower) ─── Port 8080
├── PostgreSQL Database ─── Port 5432
├── Nginx Web Server ───── Port 8081
├── PHP Application
└── HAProxy Load Balancer ─ Port 80
```

---

## 📚 Files You'll Need

| File | Purpose |
|------|---------|
| `inventory.ini` | Configure your instance IP/SSH |
| `10-deploy-everything-single-instance.yml` | Main deployment playbook |
| `08-install-awx-on-existing-instance.yml` | AWX only |
| `09-install-all-apps-on-single-instance.yml` | Apps only |

---

## 🎯 What to Do After Installation

### 1. Access AWX
```
Open: http://YOUR_IP:8080
Login: admin / AWXAdminPassword123!
```

### 2. Configure Your First Project
- Click "Projects" → "Add"
- Name: My First Project
- SCM Type: Git
- SCM URL: (your git repo)

### 3. Test the Web Application
```
Open: http://YOUR_IP
Should see: Server info and database connection status
```

### 4. Check HAProxy Statistics
```
Open: http://YOUR_IP:8404/stats
Login: admin / HAProxyStatsPassword123!
```

---

## 💡 Pro Tips

1. **Change default passwords** in `inventory.ini` before deployment
2. **Save the generated files** (they contain access credentials)
3. **Take a snapshot** of your instance after successful deployment
4. **Use Ansible Vault** for production passwords
5. **Monitor disk space** - Docker images can fill up disk

---

## 📖 Full Documentation

For detailed information, see:
- **[SINGLE-INSTANCE-DEPLOYMENT.md](SINGLE-INSTANCE-DEPLOYMENT.md)** - Complete guide
- **[README.md](README.md)** - All playbooks documentation

---

## ✅ Success Indicators

✔️ All services show "active (running)"  
✔️ AWX web interface loads  
✔️ Web application displays correctly  
✔️ HAProxy stats page accessible  
✔️ No errors in logs  

---

## 🆘 Need Help?

1. Check the logs on your instance
2. Review [SINGLE-INSTANCE-DEPLOYMENT.md](SINGLE-INSTANCE-DEPLOYMENT.md) troubleshooting section
3. Verify all prerequisites are met
4. Try re-running the playbook (it's idempotent)

---

**🎉 That's it! You're ready to deploy!**

```bash
# Remember: Just three commands!
vim inventory.ini                    # Update IP
ansible -i inventory.ini openstack_instance -m ping    # Test
ansible-playbook 10-deploy-everything-single-instance.yml -i inventory.ini  # Deploy
```

**⏱️ Total time: ~45 minutes**
