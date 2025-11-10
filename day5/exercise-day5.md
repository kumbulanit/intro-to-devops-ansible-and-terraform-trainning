# 🎓 Day 5 Comprehensive Exercise: Enterprise Ansible Project

## 🎯 Objective

Build a complete enterprise-grade Ansible project that demonstrates all Day 5 concepts:
- ✅ Best practice directory layout
- ✅ Dynamic inventory for OpenStack
- ✅ Staging vs Production environment separation
- ✅ Proper group and host variable organization
- ✅ Modular playbooks separated by server type

**Duration:** 2-3 hours  
**Difficulty:** Advanced

---

## 📋 Scenario

You are deploying a three-tier web application:
- **Load Balancer Layer** (HAProxy)
- **Web Application Layer** (Nginx + PHP-FPM)
- **Database Layer** (PostgreSQL)

Requirements:
- Separate staging and production environments
- Different configurations per environment
- Secure credential management with Ansible Vault
- Dynamic inventory for cloud instances
- Modular, maintainable code structure

---

## 🏗️ Part 1: Project Structure Setup

### Step 1: Create Directory Structure

```bash
mkdir -p ~/ansible-training/day5/final-exercise
cd ~/ansible-training/day5/final-exercise

# Create complete directory structure
mkdir -p {inventories/{production,staging}/{group_vars/{all,webservers,dbservers,loadbalancers},host_vars},roles/{common,webserver,database,loadbalancer}/{tasks,handlers,templates,files,defaults,vars,meta},playbooks,library,filter_plugins,docs}

# Create cloud inventory directory
mkdir -p inventories/cloud
```

### Step 2: Create ansible.cfg

```bash
cat > ansible.cfg << 'EOF'
[defaults]
inventory = ./inventories/production/hosts
roles_path = ./roles
host_key_checking = False
retry_files_enabled = False
gathering = smart
fact_caching = jsonfile
fact_caching_connection = /tmp/ansible_facts
fact_caching_timeout = 3600
vault_password_file = .vault_pass
deprecation_warnings = False
callbacks_enabled = profile_tasks, timer

[inventory]
enable_plugins = host_list, script, auto, yaml, ini, openstack

[privilege_escalation]
become = True
become_method = sudo
become_user = root

[ssh_connection]
pipelining = True
ssh_args = -o ControlMaster=auto -o ControlPersist=60s -o ServerAliveInterval=60
EOF
```

---

## 🏗️ Part 2: Production Environment Setup

### Step 1: Create Production Inventory

```bash
cat > inventories/production/hosts << 'EOF'
# Production Environment Inventory

[loadbalancers]
lb1.prod.example.com ansible_host=10.0.1.10

[webservers]
web1.prod.example.com ansible_host=10.0.2.10
web2.prod.example.com ansible_host=10.0.2.11
web3.prod.example.com ansible_host=10.0.2.12

[dbservers]
db1.prod.example.com ansible_host=10.0.3.10
db2.prod.example.com ansible_host=10.0.3.11

[monitoring]
monitor1.prod.example.com ansible_host=10.0.4.10

# Group of groups
[production:children]
loadbalancers
webservers
dbservers
monitoring

[production:vars]
ansible_user=ansible
ansible_python_interpreter=/usr/bin/python3
env=production
EOF
```

### Step 2: Production Global Variables

```bash
cat > inventories/production/group_vars/all/common.yml << 'EOF'
---
# Production - Common Variables

environment: production
domain: example.com
company_name: "MyCompany Inc"

# Timezone
timezone: UTC

# NTP Servers
ntp_servers:
  - 0.pool.ntp.org
  - 1.pool.ntp.org

# DNS Servers
dns_servers:
  - 8.8.8.8
  - 8.8.4.4

# Common packages
common_packages:
  - vim
  - git
  - htop
  - curl
  - wget
  - net-tools
  - tree
  - jq

# Monitoring
monitoring_enabled: true
monitoring_server: monitor1.prod.example.com
log_level: warn

# Backup
backup_enabled: true
backup_retention_days: 30
backup_server: backup.example.com

# Security
firewall_enabled: true
selinux_enabled: false
fail2ban_enabled: true
EOF
```

### Step 3: Production Secrets (Vault)

```bash
# Create vault password file (for testing only, never commit to git!)
echo "production-vault-password-123" > .vault_pass_production
chmod 600 .vault_pass_production

# Create encrypted vault file
ansible-vault create inventories/production/group_vars/all/vault.yml --vault-password-file .vault_pass_production
```

Add this content to the vault file:

```yaml
---
# Production Secrets - Encrypted

# Database
vault_db_password: "Pr0d_S3cur3_DB_P@ssw0rd"
vault_db_replication_password: "Pr0d_R3pl_P@ssw0rd"

# API Keys
vault_api_key: "prod-api-key-xyz123abc456"
vault_monitoring_api_key: "prod-monitor-key-789def"

# SSL
vault_ssl_key_password: "prod-ssl-cert-password"

# Admin credentials
vault_admin_password: "Pr0d_@dm1n_P@ss"
```

### Step 4: Production Group Variables

**Webservers:**

```bash
cat > inventories/production/group_vars/webservers.yml << 'EOF'
---
# Production Webservers Configuration

http_port: 80
https_port: 443

nginx_worker_processes: 4
nginx_worker_connections: 2048
nginx_keepalive_timeout: 65
nginx_client_max_body_size: 100M

php_version: "8.1"
php_memory_limit: 512M
php_max_execution_time: 300
php_upload_max_filesize: 100M

# SSL Configuration
ssl_enabled: true
ssl_certificate: /etc/ssl/certs/example.com.crt
ssl_key: /etc/ssl/private/example.com.key

# Application
app_name: myapp
app_user: www-data
app_group: www-data
document_root: /var/www/{{ app_name }}

# Database connection
db_host: db1.prod.example.com
db_port: 5432
db_name: myapp_prod
db_user: myapp_user
db_password: "{{ vault_db_password }}"
EOF
```

**Database Servers:**

```bash
cat > inventories/production/group_vars/dbservers.yml << 'EOF'
---
# Production Database Configuration

postgresql_version: "14"
postgresql_port: 5432
postgresql_listen_addresses: "'*'"

# Performance tuning for production
postgresql_max_connections: 500
postgresql_shared_buffers: 2GB
postgresql_effective_cache_size: 6GB
postgresql_maintenance_work_mem: 512MB
postgresql_work_mem: 10MB

# Replication
replication_enabled: true
replication_user: replicator
replication_password: "{{ vault_db_replication_password }}"

# Database
db_name: myapp_prod
db_user: myapp_user
db_password: "{{ vault_db_password }}"

# Backup
backup_schedule: "0 2 * * *"
backup_path: /backup/postgresql
EOF
```

**Load Balancers:**

```bash
cat > inventories/production/group_vars/loadbalancers.yml << 'EOF'
---
# Production Load Balancer Configuration

haproxy_version: "2.4"

# Frontend configuration
frontend_port: 80
frontend_ssl_port: 443

# Backend configuration
backend_servers: "{{ groups['webservers'] }}"
backend_port: 80

# Health check
health_check_interval: 5s
health_check_timeout: 3s
health_check_rise: 2
health_check_fall: 3

# Timeouts
client_timeout: 50s
server_timeout: 50s
connect_timeout: 10s

# Stats
stats_enabled: true
stats_port: 8080
stats_uri: /stats
stats_refresh: 5s
EOF
```

### Step 5: Production Host Variables

```bash
cat > inventories/production/host_vars/web1.prod.example.com.yml << 'EOF'
---
server_id: 1
nginx_worker_processes: 8  # Override - more powerful server
backup_schedule: "0 3 * * *"  # Different backup time
EOF

cat > inventories/production/host_vars/db1.prod.example.com.yml << 'EOF'
---
server_id: 1
replication_role: master
postgresql_shared_buffers: 4GB  # Override - more memory
backup_schedule: "0 1 * * *"
EOF

cat > inventories/production/host_vars/db2.prod.example.com.yml << 'EOF'
---
server_id: 2
replication_role: slave
replication_master: db1.prod.example.com
EOF
```

---

## 🏗️ Part 3: Staging Environment Setup

### Step 1: Create Staging Inventory

```bash
cat > inventories/staging/hosts << 'EOF'
# Staging Environment Inventory

[loadbalancers]
lb1.staging.example.com ansible_host=10.1.1.10

[webservers]
web1.staging.example.com ansible_host=10.1.2.10

[dbservers]
db1.staging.example.com ansible_host=10.1.3.10

[staging:children]
loadbalancers
webservers
dbservers

[staging:vars]
ansible_user=ansible
ansible_python_interpreter=/usr/bin/python3
env=staging
EOF
```

### Step 2: Staging Variables (Reduced Resources)

```bash
cat > inventories/staging/group_vars/all/common.yml << 'EOF'
---
# Staging - Common Variables

environment: staging
domain: staging.example.com
company_name: "MyCompany Inc - Staging"

timezone: UTC

ntp_servers:
  - 0.pool.ntp.org

dns_servers:
  - 8.8.8.8

common_packages:
  - vim
  - git
  - htop
  - curl

# Monitoring (relaxed)
monitoring_enabled: true
monitoring_server: monitor1.staging.example.com
log_level: debug  # More verbose for testing

# Backup (less frequent)
backup_enabled: true
backup_retention_days: 7  # Shorter retention
backup_server: backup.staging.example.com

# Security (relaxed for testing)
firewall_enabled: true
selinux_enabled: false
fail2ban_enabled: false
EOF
```

```bash
# Create staging vault
ansible-vault create inventories/staging/group_vars/all/vault.yml --vault-password-file .vault_pass_production
```

Add staging secrets:

```yaml
---
vault_db_password: "St@g1ng_DB_P@ss"
vault_api_key: "staging-api-key-test123"
vault_admin_password: "St@g1ng_@dm1n"
```

```bash
cat > inventories/staging/group_vars/webservers.yml << 'EOF'
---
http_port: 80
https_port: 443

# Reduced resources for staging
nginx_worker_processes: 2
nginx_worker_connections: 1024
nginx_keepalive_timeout: 65

php_version: "8.1"
php_memory_limit: 256M  # Less than production
php_max_execution_time: 300

ssl_enabled: false  # No SSL in staging

app_name: myapp
app_user: www-data
app_group: www-data
document_root: /var/www/{{ app_name }}

db_host: db1.staging.example.com
db_port: 5432
db_name: myapp_staging
db_user: myapp_user
db_password: "{{ vault_db_password }}"
EOF

cat > inventories/staging/group_vars/dbservers.yml << 'EOF'
---
postgresql_version: "14"
postgresql_port: 5432
postgresql_listen_addresses: "'*'"

# Reduced resources for staging
postgresql_max_connections: 100
postgresql_shared_buffers: 512MB
postgresql_effective_cache_size: 1GB
postgresql_work_mem: 4MB

replication_enabled: false  # No replication in staging

db_name: myapp_staging
db_user: myapp_user
db_password: "{{ vault_db_password }}"

backup_schedule: "0 3 * * 0"  # Weekly only
backup_path: /backup/postgresql
EOF
```

---

## 🏗️ Part 4: Create Roles

### Common Role

```bash
cat > roles/common/tasks/main.yml << 'EOF'
---
# Common role - tasks for all servers

- name: Update apt cache
  apt:
    update_cache: yes
    cache_valid_time: 3600
  when: ansible_os_family == "Debian"

- name: Install common packages
  package:
    name: "{{ common_packages }}"
    state: present

- name: Set timezone
  timezone:
    name: "{{ timezone }}"

- name: Configure NTP
  template:
    src: ntp.conf.j2
    dest: /etc/ntp.conf
  notify: restart ntp

- name: Create ansible user
  user:
    name: ansible
    groups: sudo
    append: yes
    shell: /bin/bash
    state: present

- name: Configure sudoers for ansible user
  lineinfile:
    path: /etc/sudoers.d/ansible
    line: 'ansible ALL=(ALL) NOPASSWD: ALL'
    create: yes
    mode: '0440'
    validate: 'visudo -cf %s'

- name: Create application log directory
  file:
    path: /var/log/myapp
    state: directory
    owner: "{{ ansible_user }}"
    mode: '0755'
EOF

cat > roles/common/handlers/main.yml << 'EOF'
---
- name: restart ntp
  service:
    name: ntp
    state: restarted
EOF

cat > roles/common/templates/ntp.conf.j2 << 'EOF'
# NTP Configuration - {{ environment }}
driftfile /var/lib/ntp/ntp.drift

{% for server in ntp_servers %}
server {{ server }} iburst
{% endfor %}

restrict default kod nomodify notrap nopeer noquery
restrict 127.0.0.1
restrict ::1
EOF
```

### Webserver Role

```bash
cat > roles/webserver/tasks/main.yml << 'EOF'
---
- name: Install Nginx
  apt:
    name: nginx
    state: present
    update_cache: yes

- name: Install PHP and extensions
  apt:
    name:
      - "php{{ php_version }}-fpm"
      - "php{{ php_version }}-mysql"
      - "php{{ php_version }}-curl"
      - "php{{ php_version }}-gd"
      - "php{{ php_version }}-mbstring"
      - "php{{ php_version }}-xml"
    state: present

- name: Create application directory
  file:
    path: "{{ document_root }}"
    state: directory
    owner: "{{ app_user }}"
    group: "{{ app_group }}"
    mode: '0755'

- name: Deploy Nginx configuration
  template:
    src: nginx.conf.j2
    dest: /etc/nginx/nginx.conf
    validate: 'nginx -t -c %s'
  notify: reload nginx

- name: Deploy site configuration
  template:
    src: site.conf.j2
    dest: /etc/nginx/sites-available/{{ app_name }}.conf
  notify: reload nginx

- name: Enable site
  file:
    src: /etc/nginx/sites-available/{{ app_name }}.conf
    dest: /etc/nginx/sites-enabled/{{ app_name }}.conf
    state: link
  notify: reload nginx

- name: Remove default site
  file:
    path: /etc/nginx/sites-enabled/default
    state: absent
  notify: reload nginx

- name: Deploy sample application
  template:
    src: index.php.j2
    dest: "{{ document_root }}/index.php"
    owner: "{{ app_user }}"
    group: "{{ app_group }}"

- name: Start and enable Nginx
  service:
    name: nginx
    state: started
    enabled: yes

- name: Start and enable PHP-FPM
  service:
    name: "php{{ php_version }}-fpm"
    state: started
    enabled: yes
EOF

cat > roles/webserver/handlers/main.yml << 'EOF'
---
- name: reload nginx
  service:
    name: nginx
    state: reloaded

- name: restart nginx
  service:
    name: nginx
    state: restarted
EOF

cat > roles/webserver/templates/index.php.j2 << 'EOF'
<?php
// {{ ansible_managed }}
echo "<h1>Welcome to {{ app_name }}</h1>";
echo "<p>Environment: {{ environment }}</p>";
echo "<p>Server: {{ inventory_hostname }}</p>";
echo "<p>PHP Version: " . phpversion() . "</p>";

// Database connection test
$db_host = "{{ db_host }}";
$db_name = "{{ db_name }}";
$db_user = "{{ db_user }}";
$db_pass = "{{ db_password }}";

try {
    $dsn = "pgsql:host=$db_host;port=5432;dbname=$db_name";
    $pdo = new PDO($dsn, $db_user, $db_pass);
    echo "<p>Database: <span style='color:green'>Connected</span></p>";
} catch (PDOException $e) {
    echo "<p>Database: <span style='color:red'>Not Connected</span></p>";
}
?>
EOF
```

---

## 🏗️ Part 5: Create Playbooks

### Master Playbook

```bash
cat > site.yml << 'EOF'
---
# Master Playbook - Complete Infrastructure Deployment

- name: Deployment Information
  hosts: localhost
  gather_facts: no
  tasks:
    - name: Display deployment banner
      debug:
        msg: |
          ╔════════════════════════════════════════╗
          ║   Multi-Tier Application Deployment    ║
          ╚════════════════════════════════════════╝
          Environment: {{ hostvars[groups['all'][0]].environment | default('UNKNOWN') }}
          Inventory: {{ inventory_file | default('UNKNOWN') }}
          Date: {{ ansible_date_time.iso8601 | default('') }}
    
    - name: Production safety check
      pause:
        prompt: |
          
          ⚠️  WARNING: PRODUCTION DEPLOYMENT ⚠️
          
          You are about to deploy to PRODUCTION!
          Press ENTER to continue or Ctrl+C to abort
      when: hostvars[groups['all'][0]].environment | default('') == 'production'

- import_playbook: playbooks/common.yml
  tags: [common, always]

- import_playbook: playbooks/database.yml
  tags: [database, db]

- import_playbook: playbooks/webservers.yml
  tags: [web, webservers]

- import_playbook: playbooks/loadbalancers.yml
  tags: [loadbalancer, lb]

- name: Deployment Complete
  hosts: localhost
  gather_facts: no
  tasks:
    - name: Display completion message
      debug:
        msg: |
          ✅ Deployment Complete!
          Environment: {{ hostvars[groups['all'][0]].environment }}
          Deployed at: {{ ansible_date_time.iso8601 }}
EOF
```

### Individual Playbooks

```bash
mkdir -p playbooks

cat > playbooks/common.yml << 'EOF'
---
- name: Common configuration for all servers
  hosts: all
  become: yes
  roles:
    - common
EOF

cat > playbooks/webservers.yml << 'EOF'
---
- name: Configure web servers
  hosts: webservers
  become: yes
  serial: "{{ web_serial | default('100%') }}"
  
  pre_tasks:
    - name: Display webserver info
      debug:
        msg: |
          Configuring: {{ inventory_hostname }}
          Nginx Workers: {{ nginx_worker_processes }}
          PHP Memory: {{ php_memory_limit }}
  
  roles:
    - webserver
  
  post_tasks:
    - name: Verify web service
      uri:
        url: "http://{{ ansible_default_ipv4.address }}:{{ http_port }}"
        return_content: yes
      register: web_result
      failed_when: false
    
    - name: Show verification result
      debug:
        msg: "Web service: {{ 'OK' if web_result.status == 200 else 'FAILED' }}"
EOF

cat > playbooks/database.yml << 'EOF'
---
- name: Configure database servers
  hosts: dbservers
  become: yes
  serial: 1  # One at a time for safety
  
  pre_tasks:
    - name: Display database info
      debug:
        msg: |
          Configuring: {{ inventory_hostname }}
          PostgreSQL: {{ postgresql_version }}
          Max Connections: {{ postgresql_max_connections }}
          Role: {{ replication_role | default('standalone') }}
  
  roles:
    - database
EOF

cat > playbooks/loadbalancers.yml << 'EOF'
---
- name: Configure load balancers
  hosts: loadbalancers
  become: yes
  
  pre_tasks:
    - name: Display LB info
      debug:
        msg: "Configuring load balancer: {{ inventory_hostname }}"
  
  roles:
    - loadbalancer
EOF
```

---

## 🏗️ Part 6: Deployment Scripts

```bash
cat > deploy-staging.sh << 'EOF'
#!/bin/bash
set -e

ENVIRONMENT="staging"
INVENTORY="inventories/staging"

echo "========================================="
echo " Deploying to STAGING"
echo "========================================="

# Syntax check
ansible-playbook -i "$INVENTORY" site.yml --syntax-check

# Dry run
echo "Running dry-run..."
ansible-playbook -i "$INVENTORY" site.yml --check

# Confirm
read -p "Deploy to staging? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo "Cancelled"
    exit 1
fi

# Deploy
ansible-playbook -i "$INVENTORY" site.yml

echo "✅ Staging deployment complete!"
EOF

cat > deploy-production.sh << 'EOF'
#!/bin/bash
set -e

ENVIRONMENT="production"
INVENTORY="inventories/production"

echo "========================================="
echo " ⚠️  PRODUCTION DEPLOYMENT ⚠️"
echo "========================================="

if [ "$1" != "--production" ]; then
    echo "ERROR: Must specify --production flag"
    exit 1
fi

# Syntax check
ansible-playbook -i "$INVENTORY" site.yml --syntax-check

# Dry run
ansible-playbook -i "$INVENTORY" site.yml --check

# Final confirmation
read -p "Type 'DEPLOY PRODUCTION': " CONFIRM
if [ "$CONFIRM" != "DEPLOY PRODUCTION" ]; then
    echo "Cancelled"
    exit 1
fi

# Deploy
ansible-playbook -i "$INVENTORY" site.yml

echo "✅ Production deployment complete!"
EOF

chmod +x deploy-staging.sh deploy-production.sh
```

---

## ✅ Testing Your Solution

### Step 1: Validate Structure

```bash
# Check directory structure
tree -L 3

# Verify inventory files
ansible-inventory -i inventories/production --list
ansible-inventory -i inventories/staging --list
```

### Step 2: Syntax Validation

```bash
# Check all playbooks
ansible-playbook -i inventories/production site.yml --syntax-check
ansible-playbook -i inventories/staging site.yml --syntax-check
```

### Step 3: List Tasks and Tags

```bash
# List all tasks
ansible-playbook -i inventories/production site.yml --list-tasks

# List all tags
ansible-playbook -i inventories/production site.yml --list-tags

# List hosts
ansible-playbook -i inventories/production site.yml --list-hosts
```

### Step 4: Dry Run

```bash
# Staging dry run
ansible-playbook -i inventories/staging site.yml --check

# Production dry run
ansible-playbook -i inventories/production site.yml --check
```

### Step 5: Selective Deployment

```bash
# Deploy only common tasks
ansible-playbook -i inventories/staging site.yml --tags common

# Deploy only web servers
ansible-playbook -i inventories/staging site.yml --tags webservers

# Deploy database and web
ansible-playbook -i inventories/staging site.yml --tags database,webservers
```

---

## 🎯 Challenge Exercises

### Challenge 1: Add Dynamic Inventory

Create OpenStack dynamic inventory configuration and provision instances with proper metadata.

### Challenge 2: Implement Rolling Updates

Modify web server playbook to do rolling updates (25% at a time).

### Challenge 3: Add Monitoring

Create a monitoring playbook that installs Prometheus node_exporter on all servers.

### Challenge 4: Implement Rollback

Create a rollback playbook that can revert to the previous version.

### Challenge 5: Add CI/CD Integration

Create a GitLab CI or GitHub Actions workflow to automate deployments.

---

## 📊 Evaluation Checklist

- [ ] Directory structure follows best practices
- [ ] Separate production and staging inventories
- [ ] Proper variable organization (group_vars, host_vars)
- [ ] Encrypted vault files for secrets
- [ ] Modular roles created
- [ ] Top-level playbooks separated by function
- [ ] Master site.yml orchestrates everything
- [ ] Tags implemented for selective execution
- [ ] Production safety checks in place
- [ ] Deployment scripts created
- [ ] All syntax checks pass
- [ ] Dry runs work correctly
- [ ] Variables properly override each other
- [ ] Documentation included

---

## 🎓 Summary

Congratulations! You've built a production-ready Ansible project that demonstrates:
- Enterprise directory layout
- Environment separation (staging/production)
- Proper variable management
- Secure credential handling
- Modular architecture
- Selective deployment capabilities

This structure can scale to manage hundreds of servers across multiple environments and is ready for team collaboration and CI/CD integration.

**You've completed Day 5! 🎉**
