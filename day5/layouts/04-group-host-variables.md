# 📊 Topic 4: Group and Host Variables

## 🎯 Objective

Master variable precedence, organization, and best practices for managing configuration data at different scopes in Ansible.

---

## 📖 Understanding Variable Scope

Ansible variables can be defined at multiple levels, each with different precedence. Understanding this hierarchy is crucial for effective configuration management.

### Variable Precedence (Lowest to Highest)

1. **role defaults** (`roles/*/defaults/main.yml`)
2. **inventory file group vars** (`[group:vars]`)
3. **inventory group_vars/all**
4. **playbook group_vars/all**
5. **inventory group_vars/** (specific group)
6. **playbook group_vars/** (specific group)
7. **inventory file host vars** (`[host] var=value`)
8. **inventory host_vars/** (specific host)
9. **playbook host_vars/** (specific host)
10. **host facts** (gathered or set)
11. **play vars**
12. **play vars_prompt**
13. **play vars_files**
14. **role vars** (`roles/*/vars/main.yml`)
15. **block vars**
16. **task vars**
17. **include_vars**
18. **set_facts / registered vars**
19. **role (and include_role) params**
20. **include params**
21. **extra vars** (`-e` command line)

**💡 Key Principle:** More specific variables override less specific ones.

---

## 📁 Group Variables Organization

### Standard Structure

```plaintext
group_vars/
├── all.yml                  # Variables for all hosts
├── all/                     # Split all vars into multiple files
│   ├── common.yml          # Common variables
│   ├── users.yml           # User definitions
│   └── vault.yml           # Encrypted secrets
├── webservers.yml          # Variables for webservers group
├── webservers/             # Split webserver vars
│   ├── nginx.yml
│   ├── php.yml
│   └── vault.yml
├── dbservers.yml           # Variables for dbservers group
├── dbservers/
│   ├── postgresql.yml
│   └── vault.yml
└── loadbalancers.yml       # Variables for loadbalancers group
```

---

## 🔧 Practical Examples

### Example 1: Basic Group Variables

**Directory Structure:**

```bash
inventories/production/
├── hosts
└── group_vars/
    ├── all.yml
    ├── webservers.yml
    └── dbservers.yml
```

**`inventories/production/hosts`**

```ini
[webservers]
web1.example.com
web2.example.com

[dbservers]
db1.example.com
db2.example.com

[loadbalancers]
lb1.example.com
```

**`inventories/production/group_vars/all.yml`**

```yaml
---
# Variables applied to ALL hosts
ntp_servers:
  - 0.pool.ntp.org
  - 1.pool.ntp.org

dns_servers:
  - 8.8.8.8
  - 8.8.4.4

timezone: UTC

common_packages:
  - vim
  - git
  - htop
  - curl
  - wget

ansible_user: ansible
ansible_python_interpreter: /usr/bin/python3

monitoring_enabled: true
log_aggregation_server: logs.example.com
```

**`inventories/production/group_vars/webservers.yml`**

```yaml
---
# Variables specific to webservers group
http_port: 80
https_port: 443

nginx_worker_processes: 4
nginx_worker_connections: 1024
nginx_keepalive_timeout: 65

max_upload_size: 100M

ssl_certificate_path: /etc/ssl/certs/example.com.crt
ssl_key_path: /etc/ssl/private/example.com.key

document_root: /var/www/html

php_version: "8.1"
php_max_execution_time: 300
php_memory_limit: 256M

app_packages:
  - nginx
  - php-fpm
  - php-mysql
  - php-curl
```

**`inventories/production/group_vars/dbservers.yml`**

```yaml
---
# Variables specific to database servers
postgresql_version: "14"
postgresql_port: 5432

postgresql_max_connections: 200
postgresql_shared_buffers: 256MB
postgresql_effective_cache_size: 1GB
postgresql_work_mem: 4MB

postgresql_data_directory: /var/lib/postgresql/14/main
postgresql_config_directory: /etc/postgresql/14/main

backup_enabled: true
backup_retention_days: 30
backup_schedule: "0 2 * * *"

replication_enabled: true
replication_user: replicator
```

---

### Example 2: Splitting Variables into Multiple Files

**For Complex Configurations:**

```plaintext
group_vars/
└── webservers/
    ├── nginx.yml
    ├── php.yml
    ├── ssl.yml
    ├── monitoring.yml
    └── vault.yml
```

**`group_vars/webservers/nginx.yml`**

```yaml
---
nginx_worker_processes: auto
nginx_worker_connections: 2048
nginx_keepalive_timeout: 65
nginx_client_max_body_size: 100M

nginx_gzip: true
nginx_gzip_types:
  - text/plain
  - text/css
  - application/json
  - application/javascript
  - text/xml

nginx_log_format: combined
nginx_access_log: /var/log/nginx/access.log
nginx_error_log: /var/log/nginx/error.log
```

**`group_vars/webservers/php.yml`**

```yaml
---
php_version: "8.1"
php_packages:
  - php{{ php_version }}-fpm
  - php{{ php_version }}-mysql
  - php{{ php_version }}-curl
  - php{{ php_version }}-gd
  - php{{ php_version }}-mbstring
  - php{{ php_version }}-xml

php_fpm_pool_user: www-data
php_fpm_pool_group: www-data
php_fpm_listen: /run/php/php{{ php_version }}-fpm.sock

php_memory_limit: 256M
php_max_execution_time: 300
php_upload_max_filesize: 100M
php_post_max_size: 100M
```

**`group_vars/webservers/ssl.yml`**

```yaml
---
ssl_enabled: true
ssl_certificate: /etc/ssl/certs/example.com.crt
ssl_certificate_key: /etc/ssl/private/example.com.key
ssl_protocols:
  - TLSv1.2
  - TLSv1.3
ssl_ciphers: HIGH:!aNULL:!MD5
ssl_prefer_server_ciphers: true
```

---

## 📍 Host Variables Organization

### Host-Specific Configuration

**Directory Structure:**

```plaintext
host_vars/
├── web1.example.com.yml
├── web2.example.com.yml
├── db1.example.com.yml
└── lb1.example.com.yml
```

**`host_vars/web1.example.com.yml`**

```yaml
---
# Host-specific variables for web1
server_id: 1
local_ip: 192.168.1.10
public_ip: 203.0.113.10

cpu_cores: 4
memory_gb: 8
disk_size_gb: 100

# Host-specific overrides
nginx_worker_processes: 4
php_memory_limit: 512M  # Override group var

# Backup configuration
backup_destination: /backup/web1
backup_retention_days: 45  # Different from group default

# Monitoring tags
monitoring_tags:
  - web
  - primary
  - production
```

**`host_vars/db1.example.com.yml`**

```yaml
---
server_id: 1
local_ip: 192.168.2.10
public_ip: 203.0.113.20

# Database-specific settings
postgresql_max_connections: 500  # Override group default
postgresql_shared_buffers: 2GB    # More memory for primary DB

# Replication settings
replication_role: master
replication_slaves:
  - db2.example.com
  - db3.example.com

# Backup settings
backup_type: full
backup_schedule: "0 1 * * *"  # Different time than group default
```

---

## 🔄 Variable Merging vs Replacement

### Hash (Dictionary) Merging

**Configure in `ansible.cfg`:**

```ini
[defaults]
hash_behaviour = merge
```

⚠️ **Warning:** This is generally **NOT recommended**. The default `hash_behaviour = replace` is safer.

### Example of Replace (Default Behavior)

**`group_vars/all.yml`**

```yaml
---
app_settings:
  debug: false
  log_level: info
  cache_enabled: true
```

**`host_vars/web1.yml`**

```yaml
---
app_settings:
  debug: true
  custom_setting: value
```

**Result:** The host_vars completely replaces the group_vars:

```yaml
app_settings:
  debug: true
  custom_setting: value
```

### Best Practice: Use Specific Variable Names

Instead of merging, use distinct variables:

**`group_vars/all.yml`**

```yaml
---
app_default_settings:
  debug: false
  log_level: info
  cache_enabled: true

app_custom_settings: {}
```

**`host_vars/web1.yml`**

```yaml
---
app_custom_settings:
  feature_x_enabled: true
  special_mode: production
```

**In Playbook/Template:**

```yaml
---
- name: Merge settings in playbook
  set_fact:
    app_settings: "{{ app_default_settings | combine(app_custom_settings) }}"
```

---

## 🛠️ Hands-On Lab: Variable Precedence

### Lab Setup

```bash
mkdir -p ~/ansible-training/day5/variables-lab/{inventories/production/{group_vars/{all,webservers,dbservers},host_vars},roles/webapp/{defaults,vars,tasks}}
cd ~/ansible-training/day5/variables-lab
```

### Step 1: Create Inventory

```bash
cat > inventories/production/hosts << 'EOF'
[webservers]
web1.example.com
web2.example.com

[dbservers]
db1.example.com

[all:vars]
ansible_connection=local
EOF
```

### Step 2: Define Variables at Different Levels

**Role Defaults (Lowest Precedence):**

```bash
cat > roles/webapp/defaults/main.yml << 'EOF'
---
app_name: myapp
app_port: 8000
app_workers: 2
log_level: info
debug_mode: false
max_connections: 100
EOF
```

**Group Variables (All):**

```bash
cat > inventories/production/group_vars/all.yml << 'EOF'
---
app_name: production-app  # Overrides role default
log_level: warn           # Overrides role default
environment: production
EOF
```

**Group Variables (Webservers):**

```bash
cat > inventories/production/group_vars/webservers.yml << 'EOF'
---
app_port: 8080           # Overrides role default
app_workers: 4           # Overrides role default
ssl_enabled: true
EOF
```

**Host Variables (web1):**

```bash
cat > inventories/production/host_vars/web1.example.com.yml << 'EOF'
---
app_workers: 8           # Overrides group var
max_connections: 500     # Overrides role default
server_id: 1
is_primary: true
EOF
```

**Role Variables (High Precedence):**

```bash
cat > roles/webapp/vars/main.yml << 'EOF'
---
app_config_path: /etc/myapp/config.yml  # Hard to override
internal_api_key: secret123             # Should use vault instead
EOF
```

### Step 3: Create Test Playbook

```bash
cat > test-precedence.yml << 'EOF'
---
- name: Test Variable Precedence
  hosts: webservers
  roles:
    - webapp
  
  vars:
    # Play-level vars (high precedence)
    debug_mode: true
  
  tasks:
    - name: Show all variable sources
      debug:
        msg: |
          === Variable Precedence Test ===
          App Name: {{ app_name }}
          App Port: {{ app_port }}
          Workers: {{ app_workers }}
          Log Level: {{ log_level }}
          Debug Mode: {{ debug_mode }}
          Max Connections: {{ max_connections }}
          Environment: {{ environment }}
          SSL Enabled: {{ ssl_enabled | default('not set') }}
          Server ID: {{ server_id | default('not set') }}
          Is Primary: {{ is_primary | default(false) }}
          Config Path: {{ app_config_path }}
    
    - name: Show variable precedence for web1 specifically
      debug:
        msg: |
          Host: {{ inventory_hostname }}
          Workers: {{ app_workers }}
          (web1 should show 8 workers, web2 should show 4)
      when: inventory_hostname is match("web.*")
    
    - name: Test extra vars (highest precedence)
      debug:
        msg: "Extra var test: {{ test_var | default('not provided') }}"
EOF
```

### Step 4: Run Tests

```bash
# Basic run
ansible-playbook -i inventories/production test-precedence.yml

# Run with extra vars (highest precedence)
ansible-playbook -i inventories/production test-precedence.yml -e "test_var=from_command_line app_name=override_everything"

# Limit to specific host
ansible-playbook -i inventories/production test-precedence.yml --limit web1.example.com
```

**Expected Output for web1:**
```yaml
App Name: production-app          # From group_vars/all
App Port: 8080                    # From group_vars/webservers
Workers: 8                        # From host_vars/web1
Log Level: warn                   # From group_vars/all
Debug Mode: true                  # From play vars
Max Connections: 500              # From host_vars/web1
Environment: production           # From group_vars/all
SSL Enabled: true                 # From group_vars/webservers
Server ID: 1                      # From host_vars/web1
Is Primary: true                  # From host_vars/web1
Config Path: /etc/myapp/config.yml  # From role vars
```

---

## 💡 Best Practices

### 1. Use Descriptive Variable Names

❌ **Bad:**
```yaml
port: 80
timeout: 30
```

✅ **Good:**
```yaml
nginx_port: 80
nginx_keepalive_timeout: 30
```

### 2. Group Related Variables

```yaml
# Good organization
nginx:
  port: 80
  worker_processes: 4
  log_path: /var/log/nginx

postgresql:
  port: 5432
  max_connections: 200
  data_directory: /var/lib/postgresql
```

### 3. Use Defaults Appropriately

**In `roles/*/defaults/main.yml`:**
```yaml
---
# These can be easily overridden
app_port: 8000
app_workers: 2
log_level: info
```

**In `roles/*/vars/main.yml`:**
```yaml
---
# These should rarely change
app_config_directory: /etc/myapp
app_log_directory: /var/log/myapp
```

### 4. Document Your Variables

```yaml
---
# Web Server Configuration
# These variables control nginx behavior

# Port number for HTTP traffic (1-65535)
nginx_http_port: 80

# Port number for HTTPS traffic (1-65535)
nginx_https_port: 443

# Number of worker processes (auto = CPU cores)
# Options: auto, number
nginx_worker_processes: auto

# Maximum number of connections per worker
nginx_worker_connections: 1024
```

### 5. Use ansible.builtin.debug for Troubleshooting

```yaml
- name: Debug variable sources
  debug:
    msg: |
      app_port value: {{ app_port }}
      app_port source: {{ lookup('vars', 'app_port', default='undefined') }}
  tags: [debug]
```

### 6. Separate Secrets

```plaintext
group_vars/
├── all/
│   ├── vars.yml          # Public variables
│   └── vault.yml         # Encrypted secrets
```

**`group_vars/all/vars.yml`:**
```yaml
---
db_host: db.example.com
db_port: 5432
db_user: appuser
db_name: production_db
db_password: "{{ vault_db_password }}"  # Reference vault
```

**`group_vars/all/vault.yml`:**
```yaml
---
vault_db_password: "encrypted_password_here"
vault_api_key: "encrypted_api_key_here"
```

---

## 📊 Variable Precedence Cheat Sheet

| Precedence | Source | Example | Override Level |
|------------|--------|---------|----------------|
| Lowest | Role defaults | `roles/*/defaults/main.yml` | Easy |
| ↓ | Inventory group vars | `[group:vars]` | Easy |
| ↓ | group_vars/all | `group_vars/all.yml` | Easy |
| ↓ | group_vars/group | `group_vars/webservers.yml` | Easy |
| ↓ | Inventory host vars | `[host] var=value` | Medium |
| ↓ | host_vars/host | `host_vars/web1.yml` | Medium |
| ↓ | Play vars | `vars:` in playbook | Hard |
| ↓ | Role vars | `roles/*/vars/main.yml` | Hard |
| ↓ | Task vars | `vars:` in task | Hard |
| Highest | Extra vars | `-e var=value` | Hardest |

---

## ✅ Checklist

- [ ] Understood variable precedence order
- [ ] Organized group_vars properly
- [ ] Created host-specific variables
- [ ] Used role defaults for customizable values
- [ ] Used role vars for fixed values
- [ ] Separated public vars from secrets
- [ ] Documented all variables
- [ ] Tested variable precedence
- [ ] Used descriptive variable names
- [ ] Avoided hash_behaviour = merge

---

## 🔗 Next Steps

Continue to **Topic 5: Top Level Playbooks Are Separated By Server Type** to learn modular playbook architecture.
