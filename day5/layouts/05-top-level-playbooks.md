# 📋 Topic 5: Top Level Playbooks Are Separated By Server Type

## 🎯 Objective

Learn how to create maintainable, modular playbook architectures by separating concerns based on server roles and functions.

---

## 📖 Why Separate Playbooks by Server Type?

**Benefits:**
- ✅ Easier to maintain and understand
- ✅ Selective execution (deploy only what's needed)
- ✅ Parallel development by different teams
- ✅ Reduced risk (changes isolated to specific services)
- ✅ Clear separation of concerns
- ✅ Reusable across environments

---

## 🏗️ Recommended Playbook Structure

### Basic Structure

```plaintext
.
├── site.yml                 # Master playbook
├── webservers.yml          # Web server configuration
├── dbservers.yml           # Database configuration
├── loadbalancers.yml       # Load balancer configuration
├── monitoring.yml          # Monitoring setup
└── common.yml              # Common tasks for all servers
```

### Advanced Structure

```plaintext
.
├── site.yml                # Master orchestration
├── playbooks/
│   ├── infrastructure/
│   │   ├── webservers.yml
│   │   ├── dbservers.yml
│   │   └── loadbalancers.yml
│   ├── application/
│   │   ├── frontend.yml
│   │   ├── backend.yml
│   │   └── api.yml
│   ├── monitoring/
│   │   ├── monitoring-servers.yml
│   │   ├── monitoring-agents.yml
│   │   └── logging.yml
│   └── security/
│       ├── firewall.yml
│       ├── ssl-certificates.yml
│       └── security-updates.yml
└── roles/
```

---

## 📝 Master Playbook Pattern

### site.yml - The Master Playbook

**Purpose:** Orchestrates all other playbooks in the correct order.

```yaml
---
# site.yml - Master playbook for complete infrastructure deployment

- name: Import common tasks for all servers
  import_playbook: common.yml
  tags: [common, always]

- name: Configure database servers
  import_playbook: dbservers.yml
  tags: [database, db]

- name: Configure web servers
  import_playbook: webservers.yml
  tags: [web, webservers]

- name: Configure load balancers
  import_playbook: loadbalancers.yml
  tags: [loadbalancer, lb]

- name: Setup monitoring
  import_playbook: monitoring.yml
  tags: [monitoring]

- name: Configure security
  import_playbook: security.yml
  tags: [security]
```

### Usage Examples

```bash
# Deploy everything
ansible-playbook -i inventories/production site.yml

# Deploy only web servers
ansible-playbook -i inventories/production site.yml --tags webservers

# Deploy database and web servers
ansible-playbook -i inventories/production site.yml --tags database,webservers

# Skip monitoring
ansible-playbook -i inventories/production site.yml --skip-tags monitoring

# Dry run
ansible-playbook -i inventories/production site.yml --check
```

---

## 📄 Individual Playbook Examples

### common.yml - Common Configuration

**Purpose:** Tasks that apply to ALL servers regardless of type.

```yaml
---
# common.yml - Common configuration for all servers

- name: Configure common settings on all servers
  hosts: all
  become: yes
  
  roles:
    - common
  
  pre_tasks:
    - name: Update package cache
      apt:
        update_cache: yes
        cache_valid_time: 3600
      when: ansible_os_family == "Debian"
    
    - name: Set hostname
      hostname:
        name: "{{ inventory_hostname }}"
  
  tasks:
    - name: Install common packages
      package:
        name:
          - vim
          - git
          - htop
          - curl
          - wget
          - net-tools
        state: present
    
    - name: Configure NTP
      template:
        src: templates/ntp.conf.j2
        dest: /etc/ntp.conf
      notify: restart ntp
    
    - name: Configure timezone
      timezone:
        name: "{{ timezone | default('UTC') }}"
    
    - name: Create ansible user
      user:
        name: ansible
        groups: sudo
        append: yes
        shell: /bin/bash
    
    - name: Set up SSH keys
      authorized_key:
        user: ansible
        key: "{{ lookup('file', '~/.ssh/id_rsa.pub') }}"
        state: present
    
    - name: Configure sudo without password
      lineinfile:
        path: /etc/sudoers.d/ansible
        line: 'ansible ALL=(ALL) NOPASSWD: ALL'
        create: yes
        mode: '0440'
        validate: 'visudo -cf %s'
  
  handlers:
    - name: restart ntp
      service:
        name: ntp
        state: restarted
```

---

### webservers.yml - Web Server Configuration

**Purpose:** Configure web servers (Nginx, Apache, etc.)

```yaml
---
# webservers.yml - Web server configuration

- name: Configure web servers
  hosts: webservers
  become: yes
  
  roles:
    - webserver
    - { role: ssl, when: ssl_enabled | default(false) }
  
  pre_tasks:
    - name: Display web server deployment info
      debug:
        msg: |
          Configuring web server: {{ inventory_hostname }}
          Environment: {{ environment }}
          HTTP Port: {{ http_port }}
          HTTPS Port: {{ https_port }}
  
  tasks:
    - name: Install Nginx
      apt:
        name: nginx
        state: present
        update_cache: yes
    
    - name: Create web root directory
      file:
        path: "{{ document_root }}"
        state: directory
        owner: www-data
        group: www-data
        mode: '0755'
    
    - name: Deploy Nginx configuration
      template:
        src: templates/nginx.conf.j2
        dest: /etc/nginx/nginx.conf
      notify: reload nginx
    
    - name: Deploy site configuration
      template:
        src: templates/site.conf.j2
        dest: /etc/nginx/sites-available/{{ site_name }}.conf
      notify: reload nginx
    
    - name: Enable site
      file:
        src: /etc/nginx/sites-available/{{ site_name }}.conf
        dest: /etc/nginx/sites-enabled/{{ site_name }}.conf
        state: link
      notify: reload nginx
    
    - name: Remove default site
      file:
        path: /etc/nginx/sites-enabled/default
        state: absent
      notify: reload nginx
    
    - name: Start and enable Nginx
      service:
        name: nginx
        state: started
        enabled: yes
    
    - name: Configure firewall for web traffic
      ufw:
        rule: allow
        port: "{{ item }}"
        proto: tcp
      loop:
        - "{{ http_port }}"
        - "{{ https_port }}"
  
  post_tasks:
    - name: Verify Nginx is running
      uri:
        url: "http://{{ ansible_default_ipv4.address }}:{{ http_port }}"
        status_code: 200
      register: web_check
      failed_when: false
    
    - name: Display verification result
      debug:
        msg: "Web server check: {{ 'SUCCESS' if web_check.status == 200 else 'FAILED' }}"
  
  handlers:
    - name: reload nginx
      service:
        name: nginx
        state: reloaded
    
    - name: restart nginx
      service:
        name: nginx
        state: restarted
```

---

### dbservers.yml - Database Server Configuration

**Purpose:** Configure database servers (PostgreSQL, MySQL, etc.)

```yaml
---
# dbservers.yml - Database server configuration

- name: Configure database servers
  hosts: dbservers
  become: yes
  serial: 1  # Deploy one at a time for safety
  
  roles:
    - database
    - { role: database-backup, when: backup_enabled | default(true) }
  
  pre_tasks:
    - name: Display database deployment info
      debug:
        msg: |
          Configuring database: {{ inventory_hostname }}
          Environment: {{ environment }}
          PostgreSQL Version: {{ postgresql_version }}
          Replication: {{ replication_enabled | default(false) }}
    
    - name: Check if database is already initialized
      stat:
        path: "{{ postgresql_data_directory }}/PG_VERSION"
      register: pg_initialized
  
  tasks:
    - name: Install PostgreSQL
      apt:
        name:
          - "postgresql-{{ postgresql_version }}"
          - "postgresql-contrib-{{ postgresql_version }}"
          - python3-psycopg2
        state: present
        update_cache: yes
    
    - name: Ensure PostgreSQL is running
      service:
        name: postgresql
        state: started
        enabled: yes
    
    - name: Configure PostgreSQL
      template:
        src: templates/postgresql.conf.j2
        dest: "{{ postgresql_config_directory }}/postgresql.conf"
        owner: postgres
        group: postgres
        mode: '0644'
      notify: restart postgresql
    
    - name: Configure pg_hba.conf
      template:
        src: templates/pg_hba.conf.j2
        dest: "{{ postgresql_config_directory }}/pg_hba.conf"
        owner: postgres
        group: postgres
        mode: '0640'
      notify: reload postgresql
    
    - name: Create application database
      postgresql_db:
        name: "{{ db_name }}"
        state: present
      become_user: postgres
    
    - name: Create application user
      postgresql_user:
        name: "{{ db_user }}"
        password: "{{ db_password }}"
        db: "{{ db_name }}"
        priv: ALL
        state: present
      become_user: postgres
    
    - name: Configure firewall for PostgreSQL
      ufw:
        rule: allow
        port: "{{ postgresql_port }}"
        proto: tcp
        from_ip: "{{ item }}"
      loop: "{{ db_allowed_hosts }}"
      when: db_allowed_hosts is defined
  
  post_tasks:
    - name: Verify PostgreSQL is accessible
      postgresql_ping:
        db: "{{ db_name }}"
        login_user: "{{ db_user }}"
        login_password: "{{ db_password }}"
      register: db_check
      failed_when: false
    
    - name: Display verification result
      debug:
        msg: "Database check: {{ 'SUCCESS' if db_check.is_available else 'FAILED' }}"
  
  handlers:
    - name: restart postgresql
      service:
        name: postgresql
        state: restarted
    
    - name: reload postgresql
      service:
        name: postgresql
        state: reloaded
```

---

### loadbalancers.yml - Load Balancer Configuration

**Purpose:** Configure load balancers (HAProxy, Nginx, etc.)

```yaml
---
# loadbalancers.yml - Load balancer configuration

- name: Get web server facts
  hosts: webservers
  gather_facts: yes
  tasks:
    - name: Collect web server IPs
      set_fact:
        web_servers: "{{ groups['webservers'] | map('extract', hostvars, 'ansible_default_ipv4') | map(attribute='address') | list }}"
      delegate_to: localhost
      delegate_facts: yes
      run_once: yes

- name: Configure load balancers
  hosts: loadbalancers
  become: yes
  
  roles:
    - loadbalancer
  
  pre_tasks:
    - name: Display load balancer info
      debug:
        msg: |
          Configuring load balancer: {{ inventory_hostname }}
          Backend servers: {{ hostvars['localhost']['web_servers'] | join(', ') }}
  
  tasks:
    - name: Install HAProxy
      apt:
        name: haproxy
        state: present
        update_cache: yes
    
    - name: Configure HAProxy
      template:
        src: templates/haproxy.cfg.j2
        dest: /etc/haproxy/haproxy.cfg
        validate: 'haproxy -f %s -c'
      notify: restart haproxy
    
    - name: Enable HAProxy
      lineinfile:
        path: /etc/default/haproxy
        regexp: '^ENABLED='
        line: 'ENABLED=1'
    
    - name: Start and enable HAProxy
      service:
        name: haproxy
        state: started
        enabled: yes
    
    - name: Configure firewall
      ufw:
        rule: allow
        port: "{{ item }}"
        proto: tcp
      loop:
        - 80
        - 443
        - 8080  # HAProxy stats
  
  post_tasks:
    - name: Verify HAProxy is running
      uri:
        url: "http://{{ ansible_default_ipv4.address }}:8080/stats"
        status_code: 200
      register: lb_check
      failed_when: false
    
    - name: Display verification result
      debug:
        msg: "Load balancer check: {{ 'SUCCESS' if lb_check.status == 200 else 'FAILED' }}"
  
  handlers:
    - name: restart haproxy
      service:
        name: haproxy
        state: restarted
```

---

### monitoring.yml - Monitoring Setup

**Purpose:** Configure monitoring agents and dashboards

```yaml
---
# monitoring.yml - Monitoring configuration

- name: Configure monitoring servers
  hosts: monitoring_servers
  become: yes
  
  roles:
    - prometheus
    - grafana
  
  tasks:
    - name: Install Prometheus
      apt:
        name: prometheus
        state: present
    
    - name: Configure Prometheus targets
      template:
        src: templates/prometheus.yml.j2
        dest: /etc/prometheus/prometheus.yml
      notify: restart prometheus

- name: Configure monitoring agents on all servers
  hosts: all
  become: yes
  
  tasks:
    - name: Install node_exporter
      apt:
        name: prometheus-node-exporter
        state: present
    
    - name: Start node_exporter
      service:
        name: prometheus-node-exporter
        state: started
        enabled: yes
    
    - name: Configure firewall for monitoring
      ufw:
        rule: allow
        port: 9100
        proto: tcp
        from_ip: "{{ monitoring_server_ip }}"
```

---

## 🛠️ Complete Hands-On Lab

### Lab: Build a Multi-Tier Application

```bash
mkdir -p ~/ansible-training/day5/multi-tier-lab/{inventories/production/{group_vars,host_vars},playbooks,roles,templates}
cd ~/ansible-training/day5/multi-tier-lab
```

### Step 1: Create Inventory

```bash
cat > inventories/production/hosts << 'EOF'
[webservers]
web1.example.com
web2.example.com

[dbservers]
db1.example.com

[loadbalancers]
lb1.example.com

[monitoring_servers]
monitor1.example.com

[all:vars]
ansible_connection=local
environment=production
EOF
```

### Step 2: Create Variables

```bash
cat > inventories/production/group_vars/all.yml << 'EOF'
---
environment: production
timezone: UTC

# Common packages
common_packages:
  - vim
  - git
  - htop

# Monitoring
monitoring_server_ip: 192.168.1.100
EOF

cat > inventories/production/group_vars/webservers.yml << 'EOF'
---
http_port: 80
https_port: 443
document_root: /var/www/html
site_name: example.com
EOF

cat > inventories/production/group_vars/dbservers.yml << 'EOF'
---
postgresql_version: 14
postgresql_port: 5432
db_name: myapp
db_user: appuser
db_password: "{{ vault_db_password }}"
postgresql_data_directory: /var/lib/postgresql/14/main
postgresql_config_directory: /etc/postgresql/14/main
EOF
```

### Step 3: Create Master Playbook

```bash
cat > site.yml << 'EOF'
---
# Master playbook for complete stack deployment

- name: Display deployment banner
  hosts: localhost
  gather_facts: no
  tasks:
    - name: Show deployment info
      debug:
        msg: |
          ========================================
          Deploying Multi-Tier Application
          Environment: {{ environment | default('unknown') }}
          ========================================

- import_playbook: playbooks/common.yml
  tags: [common, always]

- import_playbook: playbooks/dbservers.yml
  tags: [database, db]

- import_playbook: playbooks/webservers.yml
  tags: [web, webservers]

- import_playbook: playbooks/loadbalancers.yml
  tags: [loadbalancer, lb]

- import_playbook: playbooks/monitoring.yml
  tags: [monitoring]

- name: Display completion message
  hosts: localhost
  gather_facts: no
  tasks:
    - name: Show completion message
      debug:
        msg: |
          ========================================
          Deployment Complete!
          ========================================
EOF
```

### Step 4: Create Individual Playbooks

```bash
mkdir -p playbooks

cat > playbooks/common.yml << 'EOF'
---
- name: Common configuration
  hosts: all
  become: yes
  tasks:
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
EOF

cat > playbooks/webservers.yml << 'EOF'
---
- name: Configure web servers
  hosts: webservers
  become: yes
  tasks:
    - name: Install Nginx
      apt:
        name: nginx
        state: present
    
    - name: Start Nginx
      service:
        name: nginx
        state: started
        enabled: yes
    
    - name: Create index.html
      copy:
        content: |
          <!DOCTYPE html>
          <html>
          <head><title>{{ site_name }}</title></head>
          <body>
          <h1>Hello from {{ inventory_hostname }}</h1>
          <p>Environment: {{ environment }}</p>
          </body>
          </html>
        dest: "{{ document_root }}/index.html"
EOF

cat > playbooks/dbservers.yml << 'EOF'
---
- name: Configure database servers
  hosts: dbservers
  become: yes
  tasks:
    - name: Install PostgreSQL
      apt:
        name:
          - "postgresql-{{ postgresql_version }}"
          - python3-psycopg2
        state: present
    
    - name: Ensure PostgreSQL is running
      service:
        name: postgresql
        state: started
        enabled: yes
EOF

cat > playbooks/loadbalancers.yml << 'EOF'
---
- name: Configure load balancers
  hosts: loadbalancers
  become: yes
  tasks:
    - name: Install HAProxy
      apt:
        name: haproxy
        state: present
    
    - name: Start HAProxy
      service:
        name: haproxy
        state: started
        enabled: yes
EOF

cat > playbooks/monitoring.yml << 'EOF'
---
- name: Configure monitoring
  hosts: all
  become: yes
  tasks:
    - name: Install monitoring agent
      debug:
        msg: "Installing monitoring agent on {{ inventory_hostname }}"
EOF
```

### Step 5: Test the Deployment

```bash
# Syntax check
ansible-playbook -i inventories/production site.yml --syntax-check

# List all tasks
ansible-playbook -i inventories/production site.yml --list-tasks

# List all tags
ansible-playbook -i inventories/production site.yml --list-tags

# Dry run
ansible-playbook -i inventories/production site.yml --check

# Deploy only web servers
ansible-playbook -i inventories/production site.yml --tags webservers

# Deploy everything
ansible-playbook -i inventories/production site.yml
```

---

## 💡 Best Practices

1. **Use import_playbook, not include**
   - `import_playbook` is static and processed at parse time
   - Better for large, structured deployments

2. **Order matters**
   - Deploy dependencies first (databases before web servers)
   - Use `serial` for rolling deployments

3. **Use tags consistently**
   ```yaml
   tags: [webserver, web, nginx]
   ```

4. **Add pre_tasks and post_tasks**
   - `pre_tasks`: Preparation and validation
   - `post_tasks`: Verification and notification

5. **One playbook, one purpose**
   - Don't mix webserver and database logic
   - Keep playbooks focused

6. **Use meaningful names**
   ```plaintext
   ✅ webservers.yml
   ❌ server1.yml
   ```

7. **Document dependencies**
   ```yaml
   # This playbook requires:
   # - dbservers.yml to be run first
   # - group_vars/webservers.yml configured
   ```

---

## ✅ Checklist

- [ ] Created master site.yml playbook
- [ ] Separated playbooks by server type
- [ ] Used import_playbook for orchestration
- [ ] Added appropriate tags
- [ ] Included pre_tasks and post_tasks
- [ ] Tested selective execution with tags
- [ ] Documented playbook dependencies
- [ ] Verified execution order
- [ ] Added error handling
- [ ] Implemented verification checks

---

## 🎓 Summary

You've learned how to create a professional, maintainable Ansible project structure with:
- Separated playbooks by server type
- Master orchestration playbook
- Selective execution with tags
- Proper dependency management
- Verification and validation steps

This architecture scales from small projects to enterprise deployments and enables team collaboration.

**Continue to the comprehensive Day 5 Exercise to put all concepts together!**
