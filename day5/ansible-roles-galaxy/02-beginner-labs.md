# 🎓 Ansible Roles - Beginner Labs

## Lab Overview

These hands-on labs will teach you the fundamentals of Ansible roles from scratch. Each lab builds on the previous one with clear, step-by-step instructions.

### 🖥️ Testing Environment Options

You have **TWO options** for testing these labs:

#### Option 1: Local OpenStack Instance (Recommended)
Use the OpenStack instance you set up in Day 4:
```bash
# Check your OpenStack access
source ~/openstack-credentials.sh  # or your credential file
openstack server list

# Your OpenStack instance should be accessible
# IP: [Your Instance IP]
# User: ubuntu (or centos/rhel)
```

#### Option 2: Local VMs or Containers
- VirtualBox/VMware VMs
- Docker containers
- Vagrant boxes
- WSL2 (Windows Subsystem for Linux)

### 📝 Lab Environment Setup

**For All Labs, Start Here:**

```bash
# 1. Create your working directory
mkdir -p ~/ansible_training/day5/ansible-roles-galaxy/playbooks
cd ~/ansible_training/day5/ansible-roles-galaxy/playbooks

# 2. Create inventory file for your OpenStack instance
cat > inventory.ini <<EOF
[webservers]
openstack-vm ansible_host=YOUR_OPENSTACK_IP ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/your-key.pem

[databases]
openstack-vm ansible_host=YOUR_OPENSTACK_IP ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/your-key.pem

[all:vars]
ansible_python_interpreter=/usr/bin/python3
EOF

# 3. Test connectivity to your OpenStack instance
ansible all -i inventory.ini -m ping

# Expected output:
# openstack-vm | SUCCESS => {
#     "changed": false,
#     "ping": "pong"
# }

# 4. If ping fails, troubleshoot:
# - Check SSH access: ssh -i ~/.ssh/your-key.pem ubuntu@YOUR_OPENSTACK_IP
# - Verify security groups allow SSH (port 22)
# - Check floating IP is assigned
# - Verify key file permissions: chmod 600 ~/.ssh/your-key.pem
```

---

## Lab 1: Creating Your First Role - Web Server

### 🎯 Objective
Create a simple Ansible role that installs and configures Nginx web server on your OpenStack instance.

### 📋 Prerequisites
- ✅ Ansible 2.9+ installed on your control machine
- ✅ OpenStack instance running and accessible via SSH
- ✅ Inventory file configured (from setup above)
- ✅ Basic Ansible knowledge (playbooks, tasks, variables)

### ⏱️ Estimated Time
45 minutes

### 🧪 What You'll Learn
- Creating role directory structure with ansible-galaxy
- Organizing tasks, handlers, defaults, and templates
- Using variables and Jinja2 templates
- Testing roles with real infrastructure

### 🔧 Detailed Steps

#### Step 1: Create Role Structure

```bash
# Navigate to your lab workspace
cd ~/ansible_training/day5/ansible-roles-galaxy/playbooks

# Create roles directory
mkdir -p roles
cd roles

# Create role using ansible-galaxy command
ansible-galaxy init nginx-basic

# Explanation:
# - ansible-galaxy init: Creates a standard role structure
# - nginx-basic: Name of your role (can be anything)

# View the created structure
ls -la nginx-basic/

# If 'tree' is not installed, install it:
# Ubuntu/Debian: sudo apt install tree
# RHEL/CentOS: sudo yum install tree
tree nginx-basic

# Or use find command:
find nginx-basic -type f
```

**Expected Output:**
```
nginx-basic/
├── README.md              # Role documentation
├── defaults/              # Default variables (lowest precedence)
│   └── main.yml
├── files/                 # Static files to copy to target
├── handlers/              # Event-triggered tasks (like service restart)
│   └── main.yml
├── meta/                  # Role metadata (dependencies, Galaxy info)
│   └── main.yml
├── tasks/                 # Main tasks (THIS IS WHERE THE WORK HAPPENS)
│   └── main.yml
├── templates/             # Jinja2 templates (dynamic files)
├── tests/                 # Test playbooks
│   ├── inventory
│   └── test.yml
└── vars/                  # Variables (higher precedence than defaults)
    └── main.yml
```

**🔍 Understanding the Structure:**
- **tasks/**: The actual work (install packages, start services)
- **handlers/**: Special tasks triggered by changes (restart services)
- **defaults/**: Default values for variables (can be overridden)
- **templates/**: Files with variables that get processed
- **files/**: Static files copied as-is
- **vars/**: Variables that shouldn't change often
- **meta/**: Role metadata and dependencies

#### Step 2: Define Default Variables

Edit `nginx-basic/defaults/main.yml`:

```bash
# Open the file in your preferred editor
nano nginx-basic/defaults/main.yml
# or
vi nginx-basic/defaults/main.yml
```

**Add the following content:**

```yaml
---
# defaults file for nginx-basic
# These variables can be overridden in playbooks or inventory

# Nginx package name (same for most distributions)
nginx_package: nginx

# Nginx service name
nginx_service: nginx

# Nginx document root (where web files are served from)
nginx_document_root: /var/www/html

# Nginx listening port
nginx_port: 80

# Service management
nginx_enabled: true      # Enable service at boot
nginx_state: started     # Desired state of service
```

**🔍 Variable Explanation:**
- `nginx_package`: Package name to install
- `nginx_document_root`: Directory for HTML files
- `nginx_port`: Port for HTTP traffic (port 80 is standard)
- `nginx_enabled`: Whether to start service on boot
- `nginx_state`: Current desired state (started/stopped)

#### Step 3: Create Tasks

Now we'll write the main logic of our role in `nginx-basic/tasks/main.yml`:

```bash
# Edit the tasks file
nano nginx-basic/tasks/main.yml
```

**Add the following tasks:**

```yaml
---
# tasks file for nginx-basic
# Tasks execute in order from top to bottom

# Task 1: Update package cache (only on Debian/Ubuntu)
- name: Update apt cache (Debian/Ubuntu)
  apt:
    update_cache: yes
    cache_valid_time: 3600  # Cache valid for 1 hour
  when: ansible_os_family == "Debian"
  tags: packages

# Task 2: Install Nginx package
- name: Install Nginx
  package:
    name: "{{ nginx_package }}"
    state: present
  tags: packages

# Task 3: Ensure document root directory exists
- name: Ensure document root exists
  file:
    path: "{{ nginx_document_root }}"
    state: directory
    owner: www-data
    group: www-data
    mode: '0755'
  tags: config

# Task 4: Deploy a simple welcome page
- name: Create a simple index page
  copy:
    content: |
      <!DOCTYPE html>
      <html>
        <head>
          <title>Welcome to Nginx</title>
          <style>
            body { font-family: Arial, sans-serif; margin: 40px; }
            h1 { color: #009900; }
            .info { background: #f0f0f0; padding: 20px; border-radius: 5px; }
          </style>
        </head>
        <body>
          <h1>✅ Success! Nginx is configured by Ansible Role.</h1>
          <div class="info">
            <p><strong>Server:</strong> {{ ansible_hostname }}</p>
            <p><strong>IP Address:</strong> {{ ansible_default_ipv4.address }}</p>
            <p><strong>Role:</strong> nginx-basic</p>
            <p><strong>Deployed:</strong> {{ ansible_date_time.iso8601 }}</p>
          </div>
        </body>
      </html>
    dest: "{{ nginx_document_root }}/index.html"
    owner: www-data
    group: www-data
    mode: '0644'
  notify: reload nginx
  tags: content

# Task 5: Ensure Nginx service is running
- name: Ensure Nginx is running and enabled
  service:
    name: "{{ nginx_service }}"
    state: "{{ nginx_state }}"
    enabled: "{{ nginx_enabled }}"
  tags: service
```

**🔍 Task Breakdown:**
1. **Update apt cache**: Refreshes package lists (Ubuntu/Debian only)
2. **Install Nginx**: Uses the `package` module (works across distributions)
3. **Create directory**: Ensures document root exists with correct permissions
4. **Deploy content**: Creates a simple HTML page with server info
5. **Manage service**: Starts and enables Nginx service

**💡 Key Concepts:**
- `when:` Conditional execution based on facts
- `notify:` Triggers a handler if task makes changes
- `tags:` Allows running specific subsets of tasks
- `{{ variable }}`: Jinja2 variable interpolation

#### Step 4: Create Handlers

Edit `nginx-basic/handlers/main.yml`:

```yaml
---
# handlers file for nginx-basic

- name: restart nginx
  service:
    name: "{{ nginx_service }}"
    state: restarted

- name: reload nginx
  service:
    name: "{{ nginx_service }}"
    state: reloaded
```

#### Step 5: Update Metadata

Edit `nginx-basic/meta/main.yml`:

```yaml
---
galaxy_info:
  author: Your Name
  description: Basic Nginx web server role
  company: Training
  license: MIT
  min_ansible_version: 2.9
  
  platforms:
    - name: Ubuntu
      versions:
        - focal
        - jammy
    - name: Debian
      versions:
        - bullseye
  
  galaxy_tags:
    - web
    - nginx
    - webserver

dependencies: []
```

#### Step 6: Create README

Edit `nginx-basic/README.md`:

```markdown
# Nginx Basic Role

Simple Ansible role to install and configure Nginx web server.

## Requirements

- Ubuntu 20.04/22.04 or Debian 11
- Ansible 2.9+

## Role Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `nginx_package` | nginx | Package name |
| `nginx_service` | nginx | Service name |
| `nginx_port` | 80 | Listen port |
| `nginx_document_root` | /var/www/html | Web root directory |

## Example Playbook

```yaml
- hosts: webservers
  become: yes
  roles:
    - nginx-basic
```

## Testing

```bash
ansible-playbook test-playbook.yml -i inventory
```

## License

MIT
```

#### Step 7: Create Test Playbook

Now let's create a playbook to deploy our role to your OpenStack instance:

```bash
# Go back to your lab directory
cd ~/ansible_training/day5/ansible-roles-galaxy/playbooks

# Create the test playbook
nano test-nginx-role.yml
```

**Add the following content:**

```yaml
---
- name: Test Nginx Basic Role
  hosts: webservers
  become: yes
  
  roles:
    - nginx-basic
```

#### Step 8: Configure for OpenStack Instance

Update or create your `inventory.ini` file:

```bash
# Edit inventory file
nano inventory.ini
```

```ini
[webservers]
# Replace with YOUR actual OpenStack instance details
openstack-web ansible_host=YOUR_OPENSTACK_IP ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/your-openstack-key.pem

[webservers:vars]
ansible_python_interpreter=/usr/bin/python3
```

**🔍 Finding Your OpenStack Details:**

```bash
# If using OpenStack CLI:
openstack server list --long
# Look for: Name, Networks (IP), Key Name

# Or check your previous Day 4 notes
cat ~/openstack_instance_info.txt  # If you saved it
```

**🔐 Ensure Security Group Allows HTTP Traffic:**

```bash
# Check current security rules
openstack security group list
openstack security group rule list YOUR_SECURITY_GROUP

# Add HTTP rule if not present
openstack security group rule create \
  --protocol tcp \
  --dst-port 80 \
  --remote-ip 0.0.0.0/0 \
  YOUR_SECURITY_GROUP
```

#### Step 9: Test Connectivity First

**Before running the role, verify SSH access:**

```bash
# Test SSH connection
ssh -i ~/.ssh/your-openstack-key.pem ubuntu@YOUR_OPENSTACK_IP

# If SSH works, test Ansible ping
ansible webservers -i inventory.ini -m ping

# Expected output:
# openstack-web | SUCCESS => {
#     "ansible_facts": {
#         "discovered_interpreter_python": "/usr/bin/python3"
#     },
#     "changed": false,
#     "ping": "pong"
# }
```

**🐛 Troubleshooting Connection Issues:**

```bash
# If ping fails, try with verbose mode
ansible webservers -i inventory.ini -m ping -vvv

# Common issues and fixes:
# 1. Permission denied (publickey)
chmod 600 ~/.ssh/your-openstack-key.pem

# 2. Connection timeout
# - Check security group allows SSH (port 22)
# - Verify floating IP is assigned
# - Check OpenStack instance is running: openstack server show YOUR_INSTANCE

# 3. Wrong username
# Try different user: ansible_user=centos (for CentOS) or ansible_user=admin (for Debian)
```

#### Step 10: Deploy the Role

**Step-by-step deployment process:**

```bash
# 1. Check playbook syntax
ansible-playbook test-nginx-role.yml -i inventory.ini --syntax-check

# Expected output: "playbook: test-nginx-role.yml"

# 2. Do a dry run (check mode) - no changes made
ansible-playbook test-nginx-role.yml -i inventory.ini --check

# This shows what WOULD change without actually changing it

# 3. Run with verbose output (recommended for first run)
ansible-playbook test-nginx-role.yml -i inventory.ini -v

# 4. For full details, use -vvv
ansible-playbook test-nginx-role.yml -i inventory.ini -vvv

# Expected output should show:
# PLAY [Test Nginx Basic Role] ***
# TASK [Gathering Facts] ***
# TASK [nginx-basic : Update apt cache] ***
# TASK [nginx-basic : Install Nginx] ***
# TASK [nginx-basic : Ensure document root exists] ***
# TASK [nginx-basic : Create a simple index page] ***
# TASK [nginx-basic : Ensure Nginx is running and enabled] ***
# PLAY RECAP ***
# openstack-web : ok=6  changed=5  unreachable=0  failed=0
```

#### Step 11: Verify the Deployment

**Multiple verification methods:**

```bash
# 1. Check from your local machine
curl http://YOUR_OPENSTACK_IP

# Expected: HTML page with "Success! Nginx is configured by Ansible Role."

# 2. Use curl with headers to see more details
curl -I http://YOUR_OPENSTACK_IP

# Expected: HTTP/1.1 200 OK

# 3. SSH to server and verify locally
ssh -i ~/.ssh/your-key.pem ubuntu@YOUR_OPENSTACK_IP
sudo systemctl status nginx
cat /var/www/html/index.html
exit

# 4. Use Ansible ad-hoc command to check service
ansible webservers -i inventory.ini -m service -a "name=nginx" -b

# 5. Open in browser
# Navigate to: http://YOUR_OPENSTACK_IP
```

#### Step 12: Verify Idempotency

**Run the playbook again to ensure it's idempotent:**

```bash
# Run playbook a second time
ansible-playbook test-nginx-role.yml -i inventory.ini

# Expected output should show:
# PLAY RECAP ***
# openstack-web : ok=6  changed=0  unreachable=0  failed=0
#
# Note: changed=0 means no changes were made (idempotent!)
```

**🎯 Success Indicators:**
- ✅ All tasks show "ok" status
- ✅ changed=0 on second run (idempotent)
- ✅ Nginx service is running
- ✅ Port 80 is accessible
- ✅ Custom welcome page displays

**📊 Gathering Information:**

```bash
# Get server facts
ansible webservers -i inventory.ini -m setup | less

# Check specific fact
ansible webservers -i inventory.ini -m setup -a "filter=ansible_default_ipv4"

# Verify installed packages
ansible webservers -i inventory.ini -m shell -a "dpkg -l | grep nginx" -b
```

### ✅ Expected Results

1. Nginx installed successfully
2. Service running and enabled
3. Custom index page accessible
4. No errors during playbook run

### 🎓 Learning Points

- ✅ Role directory structure
- ✅ defaults vs vars
- ✅ Using handlers
- ✅ Basic role metadata
- ✅ Testing roles

---

## Lab 2: Using Role Variables and Templates

### 🎯 Objective
Enhance the Nginx role with templates and variable-driven configuration.

### 🔧 Steps

#### Step 1: Create Nginx Configuration Template

Create `nginx-basic/templates/nginx-site.conf.j2`:

```jinja2
# Nginx site configuration
# Managed by Ansible - Do not edit manually

server {
    listen {{ nginx_port }};
    listen [::]:{{ nginx_port }};

    server_name {{ nginx_server_name | default('_') }};

    root {{ nginx_document_root }};
    index index.html index.htm;

    # Logging
    access_log /var/log/nginx/{{ nginx_site_name | default('default') }}_access.log;
    error_log /var/log/nginx/{{ nginx_site_name | default('default') }}_error.log;

    location / {
        try_files $uri $uri/ =404;
    }

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    {% if nginx_enable_status_page | default(false) %}
    # Status page
    location /nginx_status {
        stub_status on;
        access_log off;
        allow 127.0.0.1;
        deny all;
    }
    {% endif %}
}
```

#### Step 2: Update Variables

Add to `nginx-basic/defaults/main.yml`:

```yaml
# Site configuration
nginx_site_name: default
nginx_server_name: _
nginx_enable_status_page: false

# Performance settings
nginx_worker_processes: auto
nginx_worker_connections: 1024
nginx_keepalive_timeout: 65

# Custom HTML content
nginx_welcome_message: "Welcome to Nginx configured by Ansible!"
```

#### Step 3: Create Custom Index Template

Create `nginx-basic/templates/index.html.j2`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{ nginx_welcome_message }}</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 50px auto;
            padding: 20px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }
        .container {
            background: rgba(255, 255, 255, 0.1);
            padding: 30px;
            border-radius: 10px;
            backdrop-filter: blur(10px);
        }
        h1 { color: #ffd700; }
        .info { background: rgba(0,0,0,0.2); padding: 15px; border-radius: 5px; margin: 10px 0; }
        .label { font-weight: bold; color: #ffd700; }
    </style>
</head>
<body>
    <div class="container">
        <h1>{{ nginx_welcome_message }}</h1>
        
        <div class="info">
            <span class="label">Server Hostname:</span> {{ ansible_hostname }}
        </div>
        
        <div class="info">
            <span class="label">Server IP:</span> {{ ansible_default_ipv4.address }}
        </div>
        
        <div class="info">
            <span class="label">Operating System:</span> {{ ansible_distribution }} {{ ansible_distribution_version }}
        </div>
        
        <div class="info">
            <span class="label">Nginx Port:</span> {{ nginx_port }}
        </div>
        
        <div class="info">
            <span class="label">Document Root:</span> {{ nginx_document_root }}
        </div>
        
        <div class="info">
            <span class="label">Configured by:</span> Ansible Role (nginx-basic)
        </div>
        
        <div class="info">
            <span class="label">Timestamp:</span> {{ ansible_date_time.iso8601 }}
        </div>
    </div>
</body>
</html>
```

#### Step 4: Update Tasks to Use Templates

Edit `nginx-basic/tasks/main.yml` and add:

```yaml
# Add after "Install Nginx" task

- name: Deploy Nginx site configuration
  template:
    src: nginx-site.conf.j2
    dest: "/etc/nginx/sites-available/{{ nginx_site_name }}"
    owner: root
    group: root
    mode: '0644'
  notify: restart nginx

- name: Enable Nginx site
  file:
    src: "/etc/nginx/sites-available/{{ nginx_site_name }}"
    dest: "/etc/nginx/sites-enabled/{{ nginx_site_name }}"
    state: link
  notify: restart nginx

- name: Remove default site (if not default)
  file:
    path: /etc/nginx/sites-enabled/default
    state: absent
  when: nginx_site_name != "default"
  notify: restart nginx

- name: Deploy custom index page from template
  template:
    src: index.html.j2
    dest: "{{ nginx_document_root }}/index.html"
    owner: www-data
    group: www-data
    mode: '0644'
```

#### Step 5: Create Test Playbook with Custom Variables

Create `test-nginx-advanced.yml`:

```yaml
---
- name: Test Nginx Role with Custom Variables
  hosts: webservers
  become: yes
  
  roles:
    - role: nginx-basic
      vars:
        nginx_port: 8080
        nginx_server_name: "myapp.local"
        nginx_site_name: "myapp"
        nginx_welcome_message: "My Custom Application Server"
        nginx_enable_status_page: true
```

#### Step 6: Run Enhanced Role

```bash
# Run with custom variables
ansible-playbook test-nginx-advanced.yml -i inventory.ini

# Verify custom port
curl http://YOUR_OPENSTACK_IP:8080

# Check status page (from server)
ssh ubuntu@YOUR_OPENSTACK_IP "curl http://localhost:8080/nginx_status"
```

### ✅ Expected Results

1. Custom Nginx configuration deployed
2. Site accessible on port 8080
3. Beautiful custom index page with server info
4. Status page available at /nginx_status

### 🎓 Learning Points

- ✅ Using Jinja2 templates
- ✅ Template variables and filters
- ✅ Conditional content in templates
- ✅ Overriding role variables
- ✅ Multiple task files

---

## Lab 3: Role Dependencies and Multi-Role Playbooks

### 🎯 Objective
Create multiple roles that work together and understand role dependencies.

### 🔧 Steps

#### Step 1: Create a Common Role

```bash
cd ~/ansible_training/day5/ansible-roles-galaxy/roles/
ansible-galaxy init common
```

Edit `common/tasks/main.yml`:

```yaml
---
# Common setup tasks

- name: Update system packages
  apt:
    update_cache: yes
    upgrade: safe
    cache_valid_time: 3600
  when: ansible_os_family == "Debian"

- name: Install common packages
  package:
    name:
      - vim
      - curl
      - wget
      - git
      - htop
      - net-tools
      - ufw
    state: present

- name: Set timezone
  timezone:
    name: "{{ common_timezone | default('UTC') }}"

- name: Configure firewall (UFW)
  ufw:
    state: enabled
    policy: deny
  when: common_firewall_enabled | default(true)

- name: Allow SSH through firewall
  ufw:
    rule: allow
    port: '22'
    proto: tcp
  when: common_firewall_enabled | default(true)
```

Edit `common/defaults/main.yml`:

```yaml
---
common_timezone: UTC
common_firewall_enabled: true
common_packages:
  - vim
  - curl
  - wget
  - git
```

#### Step 2: Create a Firewall Role

```bash
ansible-galaxy init firewall
```

Edit `firewall/tasks/main.yml`:

```yaml
---
# Firewall configuration tasks

- name: Install UFW
  package:
    name: ufw
    state: present

- name: Reset UFW to default
  ufw:
    state: reset
  when: firewall_reset | default(false)

- name: Set default incoming policy
  ufw:
    direction: incoming
    policy: "{{ firewall_default_incoming_policy }}"

- name: Set default outgoing policy
  ufw:
    direction: outgoing
    policy: "{{ firewall_default_outgoing_policy }}"

- name: Allow specified ports
  ufw:
    rule: allow
    port: "{{ item.port }}"
    proto: "{{ item.proto | default('tcp') }}"
  loop: "{{ firewall_allowed_ports }}"
  when: firewall_allowed_ports is defined

- name: Enable UFW
  ufw:
    state: enabled
```

Edit `firewall/defaults/main.yml`:

```yaml
---
firewall_default_incoming_policy: deny
firewall_default_outgoing_policy: allow
firewall_reset: false

firewall_allowed_ports:
  - port: 22
    proto: tcp
  - port: 80
    proto: tcp
  - port: 443
    proto: tcp
```

#### Step 3: Update Nginx Role with Dependencies

Edit `nginx-basic/meta/main.yml`:

```yaml
---
galaxy_info:
  author: Your Name
  description: Basic Nginx web server role
  company: Training
  license: MIT
  min_ansible_version: 2.9
  
  platforms:
    - name: Ubuntu
      versions:
        - focal
        - jammy
  
  galaxy_tags:
    - web
    - nginx

dependencies:
  - role: common
    vars:
      common_timezone: "America/New_York"
  
  - role: firewall
    vars:
      firewall_allowed_ports:
        - port: 22
          proto: tcp
        - port: "{{ nginx_port }}"
          proto: tcp
```

#### Step 4: Create Multi-Role Playbook

Create `deploy-web-stack.yml`:

```yaml
---
- name: Deploy Complete Web Stack
  hosts: webservers
  become: yes
  
  pre_tasks:
    - name: Display deployment information
      debug:
        msg:
          - "Deploying web stack to {{ inventory_hostname }}"
          - "IP: {{ ansible_host }}"
          - "OS: {{ ansible_distribution }} {{ ansible_distribution_version }}"
  
  roles:
    - role: common
      tags: common
    
    - role: firewall
      tags: firewall
      vars:
        firewall_allowed_ports:
          - port: 22
            proto: tcp
          - port: 80
            proto: tcp
          - port: 8080
            proto: tcp
    
    - role: nginx-basic
      tags: nginx
      vars:
        nginx_port: 80
        nginx_welcome_message: "Production Web Server"
  
  post_tasks:
    - name: Verify web server is accessible
      uri:
        url: "http://localhost:{{ nginx_port }}"
        status_code: 200
      register: web_check
      retries: 3
      delay: 5
    
    - name: Display success message
      debug:
        msg: "Web stack deployed successfully! Access at http://{{ ansible_host }}"
```

#### Step 5: Run Multi-Role Deployment

```bash
# Run all roles
ansible-playbook deploy-web-stack.yml -i inventory.ini

# Run specific roles using tags
ansible-playbook deploy-web-stack.yml -i inventory.ini --tags nginx

# Skip specific roles
ansible-playbook deploy-web-stack.yml -i inventory.ini --skip-tags firewall
```

### ✅ Expected Results

1. Common packages installed
2. Firewall configured and enabled
3. Nginx installed and running
4. All services working together
5. Dependencies resolved automatically

### 🎓 Learning Points

- ✅ Role dependencies
- ✅ Multiple roles in a playbook
- ✅ Role execution order
- ✅ Using tags for selective execution
- ✅ pre_tasks and post_tasks
- ✅ Variable passing between roles

---

## Lab 4: Organizing Roles with Role Path

### 🎯 Objective
Learn how to organize and manage multiple roles using ansible.cfg and role paths.

### 🔧 Steps

#### Step 1: Create Directory Structure

```bash
cd ~/ansible_training/day5/ansible-roles-galaxy/

# Create organized structure
mkdir -p {roles/custom,roles/community,roles/internal}
```

#### Step 2: Create ansible.cfg

Create `ansible.cfg`:

```ini
[defaults]
# Role paths (searched in order)
roles_path = ./roles/custom:./roles/community:./roles/internal:~/.ansible/roles:/usr/share/ansible/roles

# Inventory location
inventory = ./inventory.ini

# Other useful settings
host_key_checking = False
retry_files_enabled = False
callback_whitelist = profile_tasks, timer

[privilege_escalation]
become = True
become_method = sudo
become_user = root
become_ask_pass = False

[ssh_connection]
pipelining = True
```

#### Step 3: Move Roles to Organized Locations

```bash
# Move custom roles
mv roles/nginx-basic roles/custom/
mv roles/firewall roles/custom/
mv roles/common roles/custom/
```

#### Step 4: Test Role Discovery

Create `test-role-paths.yml`:

```yaml
---
- name: Test Role Path Discovery
  hosts: localhost
  gather_facts: no
  
  tasks:
    - name: List available roles
      command: ansible-galaxy list
      register: role_list
      changed_when: false
    
    - name: Display roles
      debug:
        msg: "{{ role_list.stdout_lines }}"
```

Run:
```bash
ansible-playbook test-role-paths.yml
```

### ✅ Expected Results

1. Roles found in custom directories
2. ansible.cfg settings applied
3. Organized role structure

### 🎓 Learning Points

- ✅ Role path configuration
- ✅ Role search order
- ✅ ansible.cfg usage
- ✅ Project organization

---

## 📝 Practice Exercises

### Exercise 1: Create MySQL Role
Create a role that installs and configures MySQL server with:
- Custom root password
- Database creation
- User creation with privileges
- Configuration file templating

### Exercise 2: Create PHP Role
Create a role that installs PHP-FPM with:
- Multiple PHP versions support
- Extension installation
- Custom php.ini configuration
- Integration with Nginx role

### Exercise 3: Create Full LEMP Stack
Combine roles to create a complete LEMP (Linux, Nginx, MySQL, PHP) stack with:
- All previous roles
- Application deployment
- Database initialization
- Health checks

---

## 🎯 Summary

**What You've Learned:**

✅ Creating basic roles with ansible-galaxy  
✅ Role directory structure  
✅ Using defaults and variables  
✅ Creating and using templates  
✅ Role dependencies  
✅ Multi-role playbooks  
✅ Role organization and paths  

**Next Steps:**
- Move to intermediate labs for Molecule testing
- Learn Galaxy integration
- Practice with real-world scenarios

---

**🎉 Congratulations! You've completed the beginner labs!**
