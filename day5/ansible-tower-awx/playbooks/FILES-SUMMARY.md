# 📦 Single Instance Deployment - Files Summary

## ✅ Created Files for Single OpenStack Instance Deployment

All files created in: `/day5/playbooks/`

---

## 🎯 Main Files

### 1. **inventory.ini** ⭐ START HERE
**Purpose:** Configure your OpenStack instance connection details

**What to do:**
- Update `YOUR_OPENSTACK_IP` with your actual IP address
- Update SSH key path if needed
- Optionally change passwords (recommended for production)

**Example:**
```ini
[openstack_instance]
openstack-server ansible_host=192.168.1.100 ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/my-key.pem
```

---

### 2. **10-deploy-everything-single-instance.yml** ⭐ MAIN DEPLOYMENT
**Purpose:** Master playbook that installs everything

**What it does:**
- Pre-flight system checks
- Installs AWX (calls playbook #8)
- Installs complete application stack (calls playbook #9)
- Final verification and summary

**Usage:**
```bash
ansible-playbook 10-deploy-everything-single-instance.yml -i inventory.ini
```

**Time:** 40-50 minutes

---

### 3. **08-install-awx-on-existing-instance.yml**
**Purpose:** Install only AWX on your existing instance

**What it does:**
- Installs Docker and Docker Compose
- Downloads and configures AWX
- Creates management scripts
- Configures firewall

**Usage:**
```bash
ansible-playbook 08-install-awx-on-existing-instance.yml -i inventory.ini
```

**Time:** 20-30 minutes

**Access:** http://YOUR_IP:8080

---

### 4. **09-install-all-apps-on-single-instance.yml**
**Purpose:** Install complete application stack (without AWX)

**What it does:**
- Installs PostgreSQL database
- Installs Nginx + PHP
- Deploys sample web application
- Installs HAProxy load balancer
- Configures all services to work together

**Usage:**
```bash
ansible-playbook 09-install-all-apps-on-single-instance.yml -i inventory.ini
```

**Time:** 10-15 minutes

**Access:** http://YOUR_IP (web app), http://YOUR_IP:8404/stats (HAProxy)

---

## 📚 Documentation Files

### 5. **SINGLE-INSTANCE-DEPLOYMENT.md** ⭐ COMPLETE GUIDE
**Purpose:** Comprehensive documentation for single instance deployment

**Contains:**
- Detailed step-by-step instructions
- Architecture diagrams
- Prerequisites and requirements
- Configuration options
- Troubleshooting guide
- Security best practices
- Management commands
- FAQs

**Read this for:** Complete understanding of the deployment

---

### 6. **QUICKSTART.md** ⭐ 3-STEP GUIDE
**Purpose:** Quick reference for fast deployment

**Contains:**
- 3 simple steps to deploy
- Quick commands
- Common troubleshooting
- Access information

**Read this for:** Fast deployment without reading everything

---

### 7. **README.md** (existing, not modified)
**Purpose:** Documentation for original multi-VM deployment

**Contains:**
- Original playbooks documentation (01-07)
- Multi-VM deployment instructions
- OpenStack provisioning guides

---

## 🎯 Which Playbook Should I Use?

### Scenario 1: Fresh Start - Install Everything
**Use:** `10-deploy-everything-single-instance.yml`
```bash
ansible-playbook 10-deploy-everything-single-instance.yml -i inventory.ini
```
**Installs:** AWX + PostgreSQL + Nginx + PHP + HAProxy

---

### Scenario 2: Only Need AWX
**Use:** `08-install-awx-on-existing-instance.yml`
```bash
ansible-playbook 08-install-awx-on-existing-instance.yml -i inventory.ini
```
**Installs:** Only AWX (Ansible Tower)

---

### Scenario 3: Have AWX, Need Application Stack
**Use:** `09-install-all-apps-on-single-instance.yml`
```bash
ansible-playbook 09-install-all-apps-on-single-instance.yml -i inventory.ini
```
**Installs:** PostgreSQL + Nginx + PHP + HAProxy (skips AWX)

---

## 📊 Deployment Architecture

```
┌─────────────────────────────────────────────────────────┐
│         Your Single OpenStack Instance                  │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  🐳 Docker Containers (AWX):                            │
│     ├─ awx-web (Port 8080)                              │
│     ├─ awx-postgres                                      │
│     └─ awx-redis                                         │
│                                                           │
│  📊 System Services (Application):                      │
│     ├─ HAProxy (Port 80) ────┐                          │
│     ├─ Nginx (Port 8081) ◄───┤                          │
│     ├─ PHP-FPM               │                          │
│     └─ PostgreSQL (Port 5432)│                          │
│                              │                          │
│  Traffic Flow:               │                          │
│     Client ──────────────────┘                          │
│                                                           │
└─────────────────────────────────────────────────────────┘
```

---

## 🔑 Access Information

After deployment, you'll have these services:

| Service | URL | Default Credentials |
|---------|-----|---------------------|
| AWX | http://YOUR_IP:8080 | admin / AWXAdminPassword123! |
| Web Application | http://YOUR_IP | (no login) |
| HAProxy Stats | http://YOUR_IP:8404/stats | admin / HAProxyStatsPassword123! |
| Direct Web | http://YOUR_IP:8081 | (no login) |
| PostgreSQL | localhost:5432 | webapp_user / WebAppDBPass123! |

**⚠️ Change default passwords in `inventory.ini` before deploying to production!**

---

## 📝 Generated Files After Deployment

These files are created on your local machine after successful deployment:

| File | Content |
|------|---------|
| `awx-access-info.txt` | AWX credentials and access information |
| `complete-stack-access-info.txt` | Complete application stack details |
| `deployment-summary-YYYY-MM-DD.txt` | Comprehensive deployment summary |

---

## 🚀 Quick Start Summary

### Step 1: Update Inventory
```bash
vim inventory.ini
# Change: YOUR_OPENSTACK_IP to your actual IP
```

### Step 2: Test Connection
```bash
ansible -i inventory.ini openstack_instance -m ping
```

### Step 3: Deploy
```bash
ansible-playbook 10-deploy-everything-single-instance.yml -i inventory.ini
```

### Step 4: Access
```
AWX: http://YOUR_IP:8080
Web App: http://YOUR_IP
```

---

## 🔧 Management

### Check Status
```bash
ssh ubuntu@YOUR_IP
sudo systemctl status docker postgresql nginx haproxy
docker ps
```

### Restart Services
```bash
sudo systemctl restart nginx
sudo systemctl restart haproxy
sudo awx-manage.sh restart
```

### View Logs
```bash
docker logs -f awx-web
sudo journalctl -u nginx -f
sudo journalctl -u haproxy -f
```

---

## 🛠️ Key Differences from Original Playbooks

### Original Playbooks (01-07)
- Provision new OpenStack VMs
- Create networks, security groups
- Deploy across multiple VMs
- One service per VM (distributed)

### New Playbooks (08-10)
- Use existing OpenStack instance ✅
- No new VM provisioning ✅
- All services on one instance ✅
- Simpler architecture ✅
- Faster deployment ✅

---

## 📚 Documentation Hierarchy

1. **QUICKSTART.md** → Fast 3-step guide
2. **SINGLE-INSTANCE-DEPLOYMENT.md** → Complete detailed guide
3. **README.md** → Original multi-VM documentation
4. **inventory.ini** → Configuration file

**Recommendation:** Start with QUICKSTART.md, refer to SINGLE-INSTANCE-DEPLOYMENT.md for details.

---

## ✅ Prerequisites Checklist

Before running any playbook:

- [ ] OpenStack instance running (Ubuntu 20.04/22.04)
- [ ] Instance has: 8GB RAM minimum, 4 CPUs minimum, 40GB disk
- [ ] SSH access with sudo privileges working
- [ ] Ansible installed on local machine (2.9+)
- [ ] Internet connectivity from instance
- [ ] Security groups allow ports: 22, 80, 8080, 8081, 8404, 5432
- [ ] Updated `inventory.ini` with correct IP and SSH key path

---

## 🎯 Success Indicators

After deployment, verify:

✅ All services show "active (running)"
```bash
sudo systemctl status docker postgresql nginx haproxy
```

✅ Docker containers running
```bash
docker ps | grep awx
```

✅ AWX API responding
```bash
curl http://localhost:8080/api/v2/ping/
```

✅ Web application accessible
```bash
curl http://localhost
```

✅ Load balancer working
```bash
curl http://localhost:80
```

---

## 🚨 Common Issues

### Issue: Playbook fails at Docker installation
**Solution:** Check disk space, internet connectivity

### Issue: AWX containers not starting
**Solution:** Check memory (need 8GB minimum), restart Docker

### Issue: Web app can't connect to database
**Solution:** Check PostgreSQL is running, verify credentials in inventory.ini

### Issue: Load balancer shows 503 error
**Solution:** Check Nginx is running on port 8081, verify HAProxy config

---

## 💡 Tips

1. **Always test SSH connection first** before running playbooks
2. **Use verbose mode** for troubleshooting: `-vvv`
3. **Run in screen/tmux** for long deployments
4. **Take instance snapshot** after successful deployment
5. **Save generated credential files** securely

---

## 📞 Support

For issues:
1. Check playbook output for errors
2. Review logs on the instance
3. Consult SINGLE-INSTANCE-DEPLOYMENT.md troubleshooting section
4. Verify all prerequisites met
5. Try re-running playbook (idempotent)

---

## 🎓 Learning Path

1. Read **QUICKSTART.md** (5 minutes)
2. Update **inventory.ini** (2 minutes)
3. Test connection (1 minute)
4. Run **10-deploy-everything-single-instance.yml** (45 minutes)
5. Access and explore services (15 minutes)
6. Read **SINGLE-INSTANCE-DEPLOYMENT.md** for details (30 minutes)

**Total learning time:** ~1.5 hours

---

## 🎉 What You've Learned

By using these playbooks, you now understand:
- Ansible playbook structure and best practices
- Docker and container orchestration
- Web server configuration (Nginx)
- Database setup (PostgreSQL)
- Load balancing (HAProxy)
- Service integration
- Firewall configuration
- Automated deployment workflows

---

**Ready to deploy? Start with `QUICKSTART.md`!** 🚀
