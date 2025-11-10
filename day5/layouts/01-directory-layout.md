# 📁 Topic 1: Directory Layout Best Practices

## 🎯 Objective

Learn how to organize Ansible projects following industry best practices for scalability, maintainability, and team collaboration.

---

## 📖 Why Directory Layout Matters

A well-organized directory structure:
- ✅ Makes projects easier to understand and maintain
- ✅ Enables team collaboration
- ✅ Scales from small to enterprise deployments
- ✅ Follows the principle of separation of concerns
- ✅ Reduces errors and improves automation reliability

---

## 🏗️ Recommended Directory Structure

### Minimal Layout (Small Projects)

```plaintext
.
├── ansible.cfg
├── inventory
├── playbook.yml
└── roles/
    └── common/
```

### Standard Layout (Medium Projects)

```plaintext
.
├── ansible.cfg
├── production
├── staging
├── site.yml
├── webservers.yml
├── dbservers.yml
├── group_vars/
│   ├── all.yml
│   ├── webservers.yml
│   └── dbservers.yml
├── host_vars/
│   ├── web1.yml
│   └── db1.yml
└── roles/
    ├── common/
    ├── webserver/
    └── database/
```

### Enterprise Layout (Large Projects)

```plaintext
.
├── ansible.cfg
├── inventories/
│   ├── production/
│   │   ├── hosts
│   │   ├── group_vars/
│   │   │   ├── all.yml
│   │   │   ├── webservers.yml
│   │   │   └── dbservers.yml
│   │   └── host_vars/
│   │       ├── web1.example.com.yml
│   │       └── db1.example.com.yml
│   └── staging/
│       ├── hosts
│       ├── group_vars/
│       └── host_vars/
├── site.yml
├── webservers.yml
├── dbservers.yml
├── loadbalancers.yml
├── monitoring.yml
├── group_vars/
│   └── all/
│       ├── vars.yml
│       └── vault.yml
├── roles/
│   ├── common/
│   ├── webserver/
│   ├── database/
│   ├── loadbalancer/
│   └── monitoring/
├── library/              # Custom modules
├── module_utils/         # Custom module utilities
├── filter_plugins/       # Custom filters
└── docs/                 # Documentation
```

---

## 🔍 Directory Breakdown

### 1. **ansible.cfg**
Configuration file for Ansible settings.

```ini
[defaults]
inventory = ./inventories/production/hosts
roles_path = ./roles
host_key_checking = False
retry_files_enabled = False
gathering = smart
fact_caching = jsonfile
fact_caching_connection = /tmp/ansible_facts
fact_caching_timeout = 3600

[privilege_escalation]
become = True
become_method = sudo
become_user = root
become_ask_pass = False

[ssh_connection]
pipelining = True
ssh_args = -o ControlMaster=auto -o ControlPersist=60s
```

### 2. **Inventory Files**
- `production` - Production environment hosts
- `staging` - Staging environment hosts
- `inventories/` - Multiple environment support

Example `production` file:
```ini
[webservers]
web1.example.com
web2.example.com

[dbservers]
db1.example.com
db2.example.com

[loadbalancers]
lb1.example.com

[all:vars]
ansible_user=ansible
ansible_python_interpreter=/usr/bin/python3
```

### 3. **Top-Level Playbooks**
- `site.yml` - Master playbook that includes all others
- `webservers.yml` - Webserver-specific tasks
- `dbservers.yml` - Database-specific tasks
- `loadbalancers.yml` - Load balancer tasks

Example `site.yml`:
```yaml
---
- import_playbook: webservers.yml
- import_playbook: dbservers.yml
- import_playbook: loadbalancers.yml
```

### 4. **group_vars/**
Variables specific to groups of hosts.

```
group_vars/
├── all.yml              # Variables for all hosts
├── all/
│   ├── vars.yml         # Common variables
│   └── vault.yml        # Encrypted secrets
├── webservers.yml       # Variables for webservers group
└── dbservers.yml        # Variables for dbservers group
```

Example `group_vars/webservers.yml`:
```yaml
---
http_port: 80
https_port: 443
max_clients: 200
document_root: /var/www/html
```

### 5. **host_vars/**
Variables specific to individual hosts.

```
host_vars/
├── web1.example.com.yml
├── web2.example.com.yml
└── db1.example.com.yml
```

Example `host_vars/web1.example.com.yml`:
```yaml
---
server_id: 1
local_storage: /mnt/data1
backup_enabled: true
```

### 6. **roles/**
Reusable role definitions.

```
roles/
├── common/
│   ├── tasks/
│   ├── handlers/
│   ├── templates/
│   ├── files/
│   ├── vars/
│   ├── defaults/
│   ├── meta/
│   └── README.md
├── webserver/
└── database/
```

### 7. **library/** (Optional)
Custom Ansible modules.

```python
#!/usr/bin/python
# library/my_custom_module.py

from ansible.module_utils.basic import AnsibleModule

def main():
    module = AnsibleModule(
        argument_spec=dict(
            name=dict(required=True, type='str'),
            state=dict(default='present', choices=['present', 'absent'])
        )
    )
    # Module logic here
    module.exit_json(changed=True, msg="Success")

if __name__ == '__main__':
    main()
```

### 8. **filter_plugins/** (Optional)
Custom Jinja2 filters.

```python
# filter_plugins/custom_filters.py

def reverse_string(s):
    return s[::-1]

class FilterModule(object):
    def filters(self):
        return {
            'reverse': reverse_string
        }
```

---

## 🛠️ Hands-On Exercise: Create a Best Practice Layout

### Step 1: Create the Directory Structure

```bash
cd ~/ansible-training/day5
mkdir -p best-practices-lab/{inventories/{production,staging}/{group_vars,host_vars},roles/{common,webserver,database}/{tasks,handlers,templates,files,defaults,vars,meta},library,filter_plugins,docs}
cd best-practices-lab
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

[privilege_escalation]
become = True
become_method = sudo

[ssh_connection]
pipelining = True
EOF
```

### Step 3: Create Production Inventory

```bash
cat > inventories/production/hosts << 'EOF'
[webservers]
web1.prod.example.com
web2.prod.example.com

[dbservers]
db1.prod.example.com

[loadbalancers]
lb1.prod.example.com

[production:children]
webservers
dbservers
loadbalancers

[production:vars]
env=production
ansible_user=ansible
EOF
```

### Step 4: Create Staging Inventory

```bash
cat > inventories/staging/hosts << 'EOF'
[webservers]
web1.staging.example.com

[dbservers]
db1.staging.example.com

[staging:children]
webservers
dbservers

[staging:vars]
env=staging
ansible_user=ansible
EOF
```

### Step 5: Create Group Variables

```bash
# All hosts variables
cat > inventories/production/group_vars/all.yml << 'EOF'
---
ntp_servers:
  - 0.pool.ntp.org
  - 1.pool.ntp.org

monitoring_enabled: true
log_level: info
EOF

# Webservers variables
cat > inventories/production/group_vars/webservers.yml << 'EOF'
---
http_port: 80
https_port: 443
max_connections: 500
keepalive_timeout: 65
EOF

# Database variables
cat > inventories/production/group_vars/dbservers.yml << 'EOF'
---
db_port: 5432
max_connections: 200
shared_buffers: 256MB
EOF
```

### Step 6: Create Host Variables

```bash
cat > inventories/production/host_vars/web1.prod.example.com.yml << 'EOF'
---
server_id: 1
local_ip: 192.168.1.10
backup_schedule: "0 2 * * *"
EOF
```

### Step 7: Create Master Playbook (site.yml)

```bash
cat > site.yml << 'EOF'
---
- name: Apply common configuration to all servers
  hosts: all
  roles:
    - common

- import_playbook: webservers.yml
- import_playbook: dbservers.yml
EOF
```

### Step 8: Create Server-Type Playbooks

```bash
cat > webservers.yml << 'EOF'
---
- name: Configure web servers
  hosts: webservers
  roles:
    - webserver
  
  tasks:
    - name: Ensure web service is running
      service:
        name: nginx
        state: started
        enabled: yes
EOF

cat > dbservers.yml << 'EOF'
---
- name: Configure database servers
  hosts: dbservers
  roles:
    - database
  
  tasks:
    - name: Ensure database service is running
      service:
        name: postgresql
        state: started
        enabled: yes
EOF
```

### Step 9: Create a Simple Role

```bash
# Common role tasks
cat > roles/common/tasks/main.yml << 'EOF'
---
- name: Update apt cache
  apt:
    update_cache: yes
    cache_valid_time: 3600
  when: ansible_os_family == "Debian"

- name: Install common packages
  package:
    name:
      - vim
      - git
      - htop
      - curl
    state: present

- name: Configure NTP
  template:
    src: ntp.conf.j2
    dest: /etc/ntp.conf
  notify: restart ntp
EOF

# Common role defaults
cat > roles/common/defaults/main.yml << 'EOF'
---
common_packages:
  - vim
  - git
  - htop
EOF

# Common role handlers
cat > roles/common/handlers/main.yml << 'EOF'
---
- name: restart ntp
  service:
    name: ntp
    state: restarted
EOF
```

### Step 10: Verify the Structure

```bash
tree -L 3
```

Expected output:
```
.
├── ansible.cfg
├── inventories/
│   ├── production/
│   │   ├── hosts
│   │   ├── group_vars/
│   │   └── host_vars/
│   └── staging/
│       ├── hosts
│       ├── group_vars/
│       └── host_vars/
├── site.yml
├── webservers.yml
├── dbservers.yml
└── roles/
    ├── common/
    ├── webserver/
    └── database/
```

### Step 11: Test the Structure

```bash
# List all hosts
ansible all --list-hosts

# Check playbook syntax
ansible-playbook site.yml --syntax-check

# Dry run
ansible-playbook site.yml --check

# View inventory graph
ansible-inventory --graph
```

---

## 💡 Best Practices Summary

1. **Keep inventories separate** - Use `inventories/` directory for multiple environments
2. **Use group_vars and host_vars** - Avoid hardcoding variables in playbooks
3. **Create focused roles** - Each role should have a single responsibility
4. **Separate playbooks by function** - webservers.yml, dbservers.yml, etc.
5. **Use a master playbook** - site.yml imports all other playbooks
6. **Document everything** - Add README.md to roles and main directory
7. **Version control** - Use Git and .gitignore for sensitive files
8. **Use ansible.cfg** - Configure project-specific settings
9. **Encrypt secrets** - Use Ansible Vault for sensitive data
10. **Test incrementally** - Use --syntax-check and --check flags

---

## 📊 Directory Layout Comparison

| Layout Type | Use Case | Team Size | Complexity |
|-------------|----------|-----------|------------|
| Minimal | Learning, POCs | 1-2 | Low |
| Standard | Small projects | 2-5 | Medium |
| Enterprise | Production systems | 5+ | High |

---

## ✅ Quick Checklist

- [ ] Created proper directory structure
- [ ] Configured ansible.cfg
- [ ] Set up separate inventories
- [ ] Organized variables in group_vars/host_vars
- [ ] Created modular roles
- [ ] Separated playbooks by server type
- [ ] Added documentation
- [ ] Tested with --syntax-check
- [ ] Version controlled with Git

---

## 🔗 Next Steps

Move on to **Topic 2: Dynamic Inventory** to learn how to integrate cloud providers.
