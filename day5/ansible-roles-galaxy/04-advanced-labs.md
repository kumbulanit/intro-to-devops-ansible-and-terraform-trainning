# 🚀 Ansible Roles - Advanced Labs

## Lab Overview

Advanced labs covering complex role architectures, OpenStack integration, security hardening, and production deployment strategies.

### 🖥️ Testing Environment

**IMPORTANT**: For all advanced labs:
- **Recommended**: Use OpenStack instances for realistic testing
- **See**: **OPENSTACK-TESTING-GUIDE.md** for complete setup
- **Security**: Ensure proper security groups configured
- **Networking**: Multiple instances may need internal networking

### 📝 Prerequisites

Before starting advanced labs:
- ✅ Completed beginner and intermediate labs
- ✅ OpenStack instance(s) accessible
- ✅ SSH keys configured
- ✅ Ansible Galaxy account (for publishing)
- ✅ GitHub account (for version control)

---

## Lab 10: Complex Role Dependencies and Collections

### 🎯 Objective
Master role dependencies, conflicts resolution, and using Ansible Collections.

### � Prerequisites
- ✅ Completed intermediate labs
- ✅ OpenStack instance available
- ✅ Understanding of Ansible Galaxy

### ⏱️ Estimated Time
90 minutes

### 🧪 What You'll Learn
- Creating roles with complex dependencies
- Conditional dependency loading
- Conflict resolution strategies
- Using Ansible Collections
- Testing dependent roles

### �🔧 Part A: Role Dependencies with Conditional Loading

#### Step 1: Create Base Infrastructure Role

**What this does**: Creates a foundational role that other roles can depend on, with optional features controlled by variables.

```bash
# Navigate to custom roles directory
cd ~/ansible_training/day5/ansible-roles-galaxy/roles/custom/

# Create base infrastructure role
ansible-galaxy init infra-base

# Navigate into new role
cd infra-base
```

**Expected output:**
```
- Role infra-base was created successfully
```

#### Step 2: Configure Role Metadata with Dependencies

**Edit meta/main.yml:**
```bash
nano meta/main.yml
```

**Replace with:**

```yaml
---
galaxy_info:
  role_name: infra_base
  author: Your Name
  description: Base infrastructure setup for all servers
  license: MIT
  min_ansible_version: "2.9"
  
  platforms:
    - name: Ubuntu
      versions:
        - focal
        - jammy

  galaxy_tags:
    - infrastructure
    - security
    - base

dependencies:
  - role: geerlingguy.ntp
    when: enable_ntp | default(true)
  
  - role: geerlingguy.security
    when: enable_security_hardening | default(true)
    vars:
      security_sudoers_passworded:
        - name: "{{ admin_user }}"
          nopasswd: false
```

Edit `defaults/main.yml`:

```yaml
---
# Feature flags
enable_ntp: true
enable_security_hardening: true
enable_firewall: true

# User management
admin_user: "admin"
admin_ssh_keys: []

# Package management
base_packages:
  - vim
  - curl
  - wget
  - git
  - htop
  - net-tools

# Security settings
ssh_port: 22
disable_root_login: true
password_authentication: false
```

Edit `tasks/main.yml`:

```yaml
---
- name: Update apt cache
  apt:
    update_cache: yes
    cache_valid_time: 3600
  when: ansible_os_family == "Debian"

- name: Install base packages
  package:
    name: "{{ base_packages }}"
    state: present

- name: Create admin user
  user:
    name: "{{ admin_user }}"
    groups: sudo
    append: yes
    create_home: yes
    shell: /bin/bash

- name: Add SSH keys for admin user
  authorized_key:
    user: "{{ admin_user }}"
    key: "{{ item }}"
    state: present
  loop: "{{ admin_ssh_keys }}"
  when: admin_ssh_keys | length > 0

- name: Configure SSH daemon
  lineinfile:
    path: /etc/ssh/sshd_config
    regexp: "{{ item.regexp }}"
    line: "{{ item.line }}"
    validate: '/usr/sbin/sshd -t -f %s'
  loop:
    - regexp: '^#?Port '
      line: "Port {{ ssh_port }}"
    - regexp: '^#?PermitRootLogin '
      line: "PermitRootLogin {{ 'no' if disable_root_login else 'yes' }}"
    - regexp: '^#?PasswordAuthentication '
      line: "PasswordAuthentication {{ 'no' if not password_authentication else 'yes' }}"
  notify: restart sshd

- name: Include firewall configuration
  include_tasks: firewall.yml
  when: enable_firewall
```

Create `tasks/firewall.yml`:

```yaml
---
- name: Install UFW
  apt:
    name: ufw
    state: present
  when: ansible_os_family == "Debian"

- name: Configure UFW defaults
  ufw:
    direction: "{{ item.direction }}"
    policy: "{{ item.policy }}"
  loop:
    - { direction: 'incoming', policy: 'deny' }
    - { direction: 'outgoing', policy: 'allow' }

- name: Allow SSH port
  ufw:
    rule: allow
    port: "{{ ssh_port }}"
    proto: tcp

- name: Enable UFW
  ufw:
    state: enabled
```

Create `handlers/main.yml`:

```yaml
---
- name: restart sshd
  service:
    name: sshd
    state: restarted
```

#### Step 2: Create Application Role with Complex Dependencies

```bash
cd ~/ansible_training/day5/ansible-roles-galaxy/roles/custom/
ansible-galaxy init webapp-stack

cd webapp-stack
```

Edit `meta/main.yml`:

```yaml
---
galaxy_info:
  role_name: webapp_stack
  description: Complete web application stack
  license: MIT
  min_ansible_version: "2.9"

dependencies:
  # Base infrastructure must run first
  - role: infra-base
    vars:
      enable_firewall: true
      admin_user: "deploy"
  
  # Database layer
  - role: geerlingguy.postgresql
    when: use_postgres | default(false)
    vars:
      postgresql_databases:
        - name: "{{ app_db_name }}"
      postgresql_users:
        - name: "{{ app_db_user }}"
          password: "{{ app_db_password }}"
  
  - role: geerlingguy.mysql
    when: use_mysql | default(false)
    vars:
      mysql_databases:
        - name: "{{ app_db_name }}"
      mysql_users:
        - name: "{{ app_db_user }}"
          password: "{{ app_db_password }}"
          priv: "{{ app_db_name }}.*:ALL"
  
  # Web server
  - role: geerlingguy.nginx
    when: use_nginx | default(true)
  
  - role: geerlingguy.apache
    when: use_apache | default(false)
  
  # Application runtime
  - role: geerlingguy.php
    when: use_php | default(false)
  
  - role: geerlingguy.nodejs
    when: use_nodejs | default(false)
```

Edit `defaults/main.yml`:

```yaml
---
# Database selection (pick one)
use_postgres: true
use_mysql: false

# Web server selection (pick one)
use_nginx: true
use_apache: false

# Runtime selection
use_php: false
use_nodejs: true

# Application configuration
app_name: "myapp"
app_db_name: "{{ app_name }}_db"
app_db_user: "{{ app_name }}_user"
app_db_password: "changeme"  # Use Vault in production!

app_repo: "https://github.com/yourorg/yourapp.git"
app_version: "main"
app_root: "/var/www/{{ app_name }}"

# Node.js specific
nodejs_version: "18.x"
nodejs_app_port: 3000

# Nginx configuration
nginx_remove_default_vhost: true
nginx_vhosts:
  - listen: "80"
    server_name: "{{ ansible_fqdn }}"
    root: "{{ app_root }}"
    index: "index.html index.htm"
    locations:
      - path: /
        proxy_pass: "http://localhost:{{ nodejs_app_port }}"
```

#### Step 3: Create requirements.yml for External Dependencies

```yaml
---
# From Galaxy
roles:
  - name: geerlingguy.ntp
    version: "2.3.0"
  
  - name: geerlingguy.security
    version: "2.1.1"
  
  - name: geerlingguy.postgresql
    version: "3.4.1"
  
  - name: geerlingguy.mysql
    version: "4.3.0"
  
  - name: geerlingguy.nginx
    version: "3.1.4"
  
  - name: geerlingguy.apache
    version: "3.2.0"
  
  - name: geerlingguy.php
    version: "4.7.0"
  
  - name: geerlingguy.nodejs
    version: "6.1.0"

# From Git repositories
  - name: custom-monitoring
    src: https://github.com/yourorg/ansible-role-monitoring.git
    version: v1.2.3
  
  - name: custom-logging
    src: https://github.com/yourorg/ansible-role-logging.git
    scm: git
    version: main

# Collections
collections:
  - name: community.general
    version: ">=5.0.0"
  
  - name: ansible.posix
    version: "1.5.1"
  
  - name: community.postgresql
    version: "2.3.0"
```

#### Step 4: Install All Dependencies

```bash
# Install roles and collections
ansible-galaxy install -r requirements.yml

# Verify installations
ansible-galaxy list
ansible-galaxy collection list
```

#### Step 5: Create Playbook Using Complex Role

Create `deploy-webapp.yml`:

```yaml
---
- name: Deploy Web Application Stack
  hosts: webservers
  become: yes
  
  vars:
    # Database choice
    use_postgres: true
    use_mysql: false
    
    # Web server choice
    use_nginx: true
    use_apache: false
    
    # Runtime
    use_nodejs: true
    use_php: false
    
    # App configuration
    app_name: "myapp"
    app_db_password: "{{ vault_app_db_password }}"
    
  pre_tasks:
    - name: Verify single database selection
      assert:
        that:
          - (use_postgres | bool) != (use_mysql | bool)
        fail_msg: "Must select exactly one database: postgres OR mysql"
    
    - name: Verify single web server selection
      assert:
        that:
          - (use_nginx | bool) != (use_apache | bool)
        fail_msg: "Must select exactly one web server: nginx OR apache"
  
  roles:
    - role: webapp-stack
  
  post_tasks:
    - name: Deploy application code
      git:
        repo: "{{ app_repo }}"
        dest: "{{ app_root }}"
        version: "{{ app_version }}"
      become_user: "{{ admin_user }}"
    
    - name: Install Node.js dependencies
      npm:
        path: "{{ app_root }}"
        state: present
      when: use_nodejs
    
    - name: Create systemd service for Node.js app
      template:
        src: nodejs-app.service.j2
        dest: "/etc/systemd/system/{{ app_name }}.service"
      when: use_nodejs
      notify: restart app
  
  handlers:
    - name: restart app
      systemd:
        name: "{{ app_name }}"
        state: restarted
        daemon_reload: yes
        enabled: yes
```

### ✅ Expected Results

1. ✅ Complex role dependencies working correctly
2. ✅ Conditional dependency loading based on variables
3. ✅ Multiple external roles integrated
4. ✅ No conflicts between similar roles

### 🎓 Learning Points

- ✅ Complex dependency chains
- ✅ Conditional dependencies
- ✅ requirements.yml management
- ✅ Conflict resolution strategies
- ✅ Collections integration

---

## Lab 11: Testing Roles with Real OpenStack Instance

### 🎯 Objective
Test roles against your actual OpenStack instance using Molecule with cloud drivers and manual deployment methods.

### 📋 Prerequisites
- ✅ Completed Lab 10 (Complex dependencies)
- ✅ OpenStack instance accessible from Day 4
- ✅ OpenStack CLI configured
- ✅ SSH key pair created
- ✅ Floating IPs available

### ⏱️ Estimated Time
120 minutes

### 🧪 What You'll Learn
- Molecule with OpenStack driver
- Direct OpenStack deployment testing
- Cloud infrastructure testing strategies
- Production-like environment validation
- Security group configuration
- Network troubleshooting

### 🔧 Part A: Configure Molecule for OpenStack (Optional Advanced Method)

**Note**: This section shows the advanced Molecule+OpenStack integration. If you prefer simpler direct testing, skip to Part B.

#### Step 1: Install OpenStack Molecule Driver

**What this does**: Installs the OpenStack SDK and Molecule driver for automated cloud testing.

```bash
# Navigate to your working directory
cd ~/ansible_training/day5/advanced-labs

# Install OpenStack SDK
pip3 install --user openstacksdk

# Install Molecule OpenStack driver
pip3 install --user molecule-openstack

# Verify installations
python3 -c "import openstack; print('✅ OpenStack SDK installed')"
python3 -c "import molecule_openstack; print('✅ Molecule OpenStack driver installed')"

# Check Molecule recognizes the driver
molecule drivers
```

**Expected output:**
```
✅ OpenStack SDK installed
✅ Molecule OpenStack driver installed

Available drivers:
  docker
  openstack
  podman
  ...
```

**Troubleshooting:**
- **Error: "No module named 'openstack'"**: Run `pip3 install --user openstacksdk` again
- **Permission denied**: Use `--user` flag or create virtual environment
- **molecule drivers doesn't show openstack**: Reinstall with `pip3 install --force-reinstall molecule-openstack`

#### Step 2: Configure clouds.yaml

**What this does**: Configures OpenStack credentials for Molecule to use.

**Create config directory:**
```bash
mkdir -p ~/.config/openstack
nano ~/.config/openstack/clouds.yaml
```

**Add your OpenStack configuration:**
```yaml
---
clouds:
  devstack:
    auth:
      auth_url: http://your-openstack-ip:5000/v3
      username: "admin"
      password: "your_password"
      project_name: "admin"
      domain_name: "default"
      user_domain_name: "default"
      project_domain_name: "default"
    region_name: "RegionOne"
    interface: "public"
    identity_api_version: 3
```

**Configuration explained:**
- `clouds.devstack`: Cloud profile name (use in Molecule)
- `auth_url`: Your OpenStack Keystone endpoint (from Day 4)
- `username`/`password`: Your OpenStack credentials
- `project_name`: OpenStack project/tenant
- `domain_name`: Default domain for users/projects

**Get your OpenStack details:**
```bash
# Get auth URL
openstack catalog show keystone -f value -c endpoints | grep public

# Verify credentials work
openstack server list

# If this works, your clouds.yaml is correct
```

**Save the file** (Ctrl+O, Enter, Ctrl+X)

#### Step 3: Create OpenStack Molecule Scenario

**What this does**: Creates a Molecule test scenario that provisions real OpenStack instances.

```bash
cd ~/ansible_training/day5/ansible-roles-galaxy/roles/custom/webapp-stack/

# Create OpenStack scenario (in addition to default Docker scenario)
molecule init scenario openstack --driver-name openstack
```

**Expected output:**
```
--> Initializing new scenario openstack...
Initialized scenario in /path/to/webapp-stack/molecule/openstack successfully.
```

**Edit the OpenStack scenario configuration:**
```bash
nano molecule/openstack/molecule.yml
```

**Replace with:**

```yaml
---
dependency:
  name: galaxy
  options:
    requirements-file: requirements.yml

driver:
  name: openstack

platforms:
  - name: webapp-test-ubuntu
    cloud: devstack
    image: "ubuntu-22.04"
    flavor: "m1.medium"
    network: "private"
    security_groups:
      - default
      - web
    floating_ip_pool: "public"
    boot_from_volume: false

provisioner:
  name: ansible
  config_options:
    defaults:
      host_key_checking: false
      callbacks_enabled: profile_tasks, timer
  inventory:
    host_vars:
      webapp-test-ubuntu:
        ansible_user: ubuntu
        ansible_become: yes
        use_postgres: true
        use_nginx: true
        use_nodejs: true

verifier:
  name: ansible
```

**Configuration explained:**
- `driver: openstack`: Uses OpenStack instead of Docker
- `cloud: devstack`: References clouds.yaml profile
- `image`: OpenStack image name (check with `openstack image list`)
- `flavor`: Instance size (check with `openstack flavor list`)
- `network`: Private network for instance
- `security_groups`: Firewall rules (must exist in OpenStack)
- `floating_ip_pool`: Public IP pool for external access

**Save the file**

#### Step 4: Create prepare.yml for OpenStack

**What this does**: Prepares the OpenStack instance before running your role (installs Python, updates packages).

**Create prepare playbook:**
```bash
nano molecule/openstack/prepare.yml
```

**Add:**
```yaml
---
- name: Prepare OpenStack instance
  hosts: all
  gather_facts: false
  tasks:
    - name: Wait for SSH
      wait_for_connection:
        timeout: 300
    
    - name: Gather facts
      setup:
    
    - name: Install Python for Ansible
      raw: |
        if ! command -v python3 > /dev/null; then
          apt-get update && apt-get install -y python3 python3-apt
        fi
      become: yes
      changed_when: false
    
    - name: Update apt cache
      apt:
        update_cache: yes
        cache_valid_time: 3600
      become: yes
```

**Save the file**

#### Step 5: Test on Real OpenStack with Molecule

**What this does**: Runs Molecule test but provisions real OpenStack infrastructure instead of Docker containers.

```bash
# Set OpenStack credentials
export OS_CLOUD=devstack

# Run full test on OpenStack (this will take 10-15 minutes)
molecule test -s openstack

# Or run individual steps:

# 1. Create OpenStack instance
molecule create -s openstack

# 2. Apply the role
molecule converge -s openstack

# 3. Verify
molecule verify -s openstack

# 4. Login to instance (for debugging)
molecule login -s openstack

# 5. Destroy when done
molecule destroy -s openstack
```

**Expected output:**
```
INFO     openstack scenario test matrix: dependency, lint, cleanup, destroy, syntax, create, prepare, converge, idempotence, side_effect, verify, cleanup, destroy
INFO     Running openstack > create
...
TASK [Create OpenStack instance] *******************************************
changed: [localhost]
...
PLAY RECAP *****************************************************************
webapp-test-ubuntu         : ok=15   changed=10   unreachable=0    failed=0
```

**Success indicators:**
- ✅ Instance created in OpenStack
- ✅ Floating IP assigned and accessible
- ✅ Role applied successfully
- ✅ Verification tests pass

**Troubleshooting Molecule OpenStack:**
```bash
# Check OpenStack authentication
openstack server list

# View Molecule debug output
molecule --debug create -s openstack

# Check instance console (if stuck)
openstack console log show webapp-test-ubuntu

# Manual SSH test (get IP first)
openstack server list
ssh ubuntu@<FLOATING_IP>
```

---

### 🔧 Part B: Direct OpenStack Testing (Recommended for Most Users)

**Why this method?**: Simpler, more direct control, easier to debug, and mimics production deployment.

#### Step 6: Prepare OpenStack Instance Manually

**What this does**: Creates an OpenStack instance using the skills from Day 4, specifically for role testing.

```bash
# Navigate to working directory
cd ~/ansible_training/day5/ansible-roles-galaxy/advanced-labs

# Check available resources
openstack image list
openstack flavor list
openstack network list
openstack security group list
```

**Create security group for web application testing:**
```bash
# Create security group
openstack security group create webapp-test-sg --description "Security group for webapp role testing"

# Allow SSH
openstack security group rule create --protocol tcp --dst-port 22 --remote-ip 0.0.0.0/0 webapp-test-sg

# Allow HTTP
openstack security group rule create --protocol tcp --dst-port 80 --remote-ip 0.0.0.0/0 webapp-test-sg

# Allow HTTPS
openstack security group rule create --protocol tcp --dst-port 443 --remote-ip 0.0.0.0/0 webapp-test-sg

# Allow PostgreSQL (if testing database)
openstack security group rule create --protocol tcp --dst-port 5432 --remote-ip 0.0.0.0/0 webapp-test-sg

# Allow Node.js app (example port)
openstack security group rule create --protocol tcp --dst-port 3000 --remote-ip 0.0.0.0/0 webapp-test-sg

# Verify rules
openstack security group rule list webapp-test-sg
```

**Create OpenStack instance:**
```bash
# Create instance for testing
openstack server create \
  --flavor m1.medium \
  --image Ubuntu-22.04 \
  --key-name ansible-key \
  --security-group default \
  --security-group webapp-test-sg \
  --network private \
  webapp-role-test

# Wait for instance to be ACTIVE
openstack server list

# Create and assign floating IP
FLOATING_IP=$(openstack floating ip create public -f value -c floating_ip_address)
echo "Floating IP: $FLOATING_IP"
openstack server add floating ip webapp-role-test $FLOATING_IP

# Verify instance is accessible
ping -c 3 $FLOATING_IP
```

**Expected output:**
```
+--------------------------------------+-----------------+
| ID                                   | Name            |
+--------------------------------------+-----------------+
| abc123...                            | webapp-role-test|
+--------------------------------------+-----------------+

Floating IP: 192.168.1.100

PING 192.168.1.100: 64 bytes from 192.168.1.100: icmp_seq=0 ttl=64 time=1.2 ms
```

#### Step 7: Create Inventory for Direct Testing

**Create inventory file:**
```bash
nano inventory-webapp-test.ini
```

**Add:**
```ini
[webapp_servers]
webapp-test ansible_host=192.168.1.100 ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/ansible-key

[webapp_servers:vars]
ansible_python_interpreter=/usr/bin/python3

# Role variables
use_postgres=true
use_nginx=true
use_nodejs=true
postgres_version=14
nodejs_version=18
```

**Replace `192.168.1.100` with your actual floating IP**

**Save the file**

#### Step 8: Test Connectivity

**Test SSH and Ansible connectivity:**
```bash
# Test SSH directly
ssh -i ~/.ssh/ansible-key ubuntu@192.168.1.100
# Type 'exit' to logout

# Test Ansible ping
ansible webapp_servers -i inventory-webapp-test.ini -m ping

# Gather facts to verify Python
ansible webapp_servers -i inventory-webapp-test.ini -m setup | grep ansible_python_version
```

**Expected output:**
```
webapp-test | SUCCESS => {
    "changed": false,
    "ping": "pong"
}

"ansible_python_version": "3.10.12"
```

#### Step 9: Create Test Playbook

**Create playbook to test your webapp-stack role:**
```bash
nano test-webapp-openstack.yml
```

**Add:**
```yaml
---
- name: Deploy webapp-stack role to OpenStack
  hosts: webapp_servers
  become: yes
  
  pre_tasks:
    - name: Update apt cache
      apt:
        update_cache: yes
        cache_valid_time: 3600
      tags: always
    
    - name: Display instance information
      debug:
        msg: |
          Deploying to: {{ ansible_hostname }}
          IP: {{ ansible_default_ipv4.address }}
          OS: {{ ansible_distribution }} {{ ansible_distribution_version }}
      tags: always
  
  roles:
    - role: ~/ansible_training/day5/ansible-roles-galaxy/roles/custom/webapp-stack
      vars:
        use_postgres: true
        use_nginx: true
        use_nodejs: true
  
  post_tasks:
    - name: Display deployment summary
      debug:
        msg: |
          ✅ Deployment complete!
          Web server: http://{{ ansible_host }}
          Check application: http://{{ ansible_host }}:3000
      tags: always
```

**Save the file**

#### Step 10: Deploy Role to OpenStack

**Run the playbook with detailed output:**
```bash
# Syntax check
ansible-playbook test-webapp-openstack.yml -i inventory-webapp-test.ini --syntax-check

# Dry run (see what would change)
ansible-playbook test-webapp-openstack.yml -i inventory-webapp-test.ini --check --diff

# Deploy with verbose output
ansible-playbook test-webapp-openstack.yml -i inventory-webapp-test.ini -v

# For troubleshooting, use extra verbosity
# ansible-playbook test-webapp-openstack.yml -i inventory-webapp-test.ini -vvv
```

**Expected output:**
```
PLAY [Deploy webapp-stack role to OpenStack] *******************************

TASK [Gathering Facts] *****************************************************
ok: [webapp-test]

TASK [Display instance information] ****************************************
ok: [webapp-test] => {
    "msg": "Deploying to: webapp-role-test\nIP: 10.0.0.5\nOS: Ubuntu 22.04\n"
}

TASK [webapp-stack : Include PostgreSQL tasks] *****************************
included: /path/to/roles/webapp-stack/tasks/postgres.yml for webapp-test

... (many tasks) ...

PLAY RECAP *****************************************************************
webapp-test                : ok=35   changed=25   unreachable=0    failed=0
```

**Success indicators:**
- ✅ No failed tasks (`failed=0`)
- ✅ All expected services installed
- ✅ Post-deployment summary displayed

#### Step 11: Verify Deployment on OpenStack

**Comprehensive verification:**

**1. Test HTTP endpoints:**
```bash
# Get your floating IP
FLOATING_IP=$(openstack server show webapp-role-test -f value -c addresses | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | tail -1)

# Test Nginx
curl http://$FLOATING_IP

# Test Node.js application (if deployed)
curl http://$FLOATING_IP:3000

# Check HTTP headers
curl -I http://$FLOATING_IP
```

**2. SSH to instance for detailed checks:**
```bash
ssh -i ~/.ssh/ansible-key ubuntu@$FLOATING_IP

# Check PostgreSQL
sudo systemctl status postgresql
sudo -u postgres psql -c "SELECT version();"

# Check Nginx
sudo systemctl status nginx
sudo nginx -t

# Check Node.js
node --version
npm --version

# Check listening ports
sudo ss -tlnp | grep LISTEN

# Check logs
sudo tail -20 /var/log/nginx/access.log
sudo journalctl -u nginx -n 20

# Exit when done
exit
```

**3. Run verification playbook:**
```bash
# Create verification playbook
cat << 'EOF' > verify-webapp-deployment.yml
---
- name: Verify webapp-stack deployment
  hosts: webapp_servers
  become: yes
  gather_facts: yes
  
  tasks:
    - name: Check Nginx is installed and running
      service_facts:
      
    - name: Assert Nginx is running
      assert:
        that:
          - "'nginx.service' in services"
          - "services['nginx.service'].state == 'running'"
        success_msg: "✅ Nginx is running"
        fail_msg: "❌ Nginx is not running"
    
    - name: Check PostgreSQL is running (if enabled)
      assert:
        that:
          - "'postgresql.service' in services"
          - "services['postgresql.service'].state == 'running'"
        success_msg: "✅ PostgreSQL is running"
        fail_msg: "❌ PostgreSQL is not running"
      when: use_postgres | default(false)
    
    - name: Test Nginx responds to HTTP
      uri:
        url: http://localhost
        status_code: 200
      register: nginx_response
    
    - name: Display verification results
      debug:
        msg: |
          ✅ All verification tests passed!
          Nginx: {{ services['nginx.service'].state }}
          PostgreSQL: {{ services['postgresql.service'].state | default('Not installed') }}
          HTTP response: {{ nginx_response.status }}
EOF

# Run verification
ansible-playbook verify-webapp-deployment.yml -i inventory-webapp-test.ini
```

**Expected output:**
```
TASK [Assert Nginx is running] *********************************************
ok: [webapp-test] => {
    "changed": false,
    "msg": "✅ Nginx is running"
}

TASK [Assert PostgreSQL is running (if enabled)] ***************************
ok: [webapp-test] => {
    "changed": false,
    "msg": "✅ PostgreSQL is running"
}

TASK [Test Nginx responds to HTTP] *****************************************
ok: [webapp-test]

TASK [Display verification results] ****************************************
ok: [webapp-test] => {
    "msg": "✅ All verification tests passed!\nNginx: running\nPostgreSQL: running\nHTTP response: 200\n"
}
```

#### Step 12: Test Idempotency on OpenStack

**Re-run playbook to verify idempotency:**
```bash
ansible-playbook test-webapp-openstack.yml -i inventory-webapp-test.ini -v
```

**Expected result:**
```
PLAY RECAP *****************************************************************
webapp-test                : ok=35   changed=0    unreachable=0    failed=0
```

**✅ Success**: `changed=0` indicates perfect idempotency

**If changed > 0, investigate:**
```bash
# Run with diff to see what's changing
ansible-playbook test-webapp-openstack.yml -i inventory-webapp-test.ini --check --diff

# Common issues:
# - Package updates (use state: present, not latest)
# - File timestamps (use proper comparisons)
# - Service restarts (check handler triggers)
```

#### Step 13: Cleanup OpenStack Resources

**When testing is complete:**
```bash
# View current resources
openstack server list
openstack floating ip list

# Delete the test instance
openstack server delete webapp-role-test

# Release floating IP (optional)
openstack floating ip delete $FLOATING_IP

# Delete security group (optional)
openstack security group delete webapp-test-sg

# Verify cleanup
openstack server list
```

### ✅ Expected Results (Complete Lab 11)
molecule test -s openstack

# Or step-by-step:
molecule create -s openstack      # Create VM
molecule converge -s openstack    # Deploy role
molecule verify -s openstack      # Run tests
molecule login -s openstack       # SSH to VM
molecule destroy -s openstack     # Clean up
```

### ✅ Expected Results

1. ✅ VM created in OpenStack
2. ✅ Role deployed to real cloud instance
3. ✅ All services running on cloud VM
4. ✅ Tests passing on production-like environment

### 🎓 Learning Points

- ✅ OpenStack Molecule driver
- ✅ Cloud-based testing
- ✅ Production-like test environments
- ✅ CI/CD with cloud resources

---

## Lab 12: Role Security Hardening and Vault Integration

### 🎯 Objective

Implement security best practices and integrate Ansible Vault for sensitive data.

### 🔧 Part A: Secure Role Development

#### Step 1: Create Security-Hardened Role

```bash
ansible-galaxy init secure-webapp

cd secure-webapp
```

Edit `defaults/main.yml`:

```yaml
---
# Security settings
security_ssh_port: 2222
security_fail2ban_enabled: true
security_ufw_enabled: true

# Application settings (non-sensitive defaults)
app_name: "secure-app"
app_port: 3000
app_user: "appuser"
app_group: "appgroup"

# Database settings (override with vault)
db_host: "localhost"
db_port: 5432
db_name: "{{ app_name }}_db"
db_user: "{{ app_name }}_user"
# db_password: defined in vault

# SSL/TLS
ssl_enabled: true
ssl_cert_path: "/etc/ssl/certs/{{ app_name }}.crt"
ssl_key_path: "/etc/ssl/private/{{ app_name }}.key"
# ssl_key_passphrase: defined in vault

# Secrets (all defined in vault)
# jwt_secret: defined in vault
# api_key: defined in vault
# session_secret: defined in vault
```

#### Step 2: Create Vault Files

```bash
# Create vault password file
echo "your-strong-vault-password" > .vault_pass
chmod 600 .vault_pass

# Add to .gitignore
echo ".vault_pass" >> .gitignore
```

Create encrypted variables file:

```bash
# Create vault file
ansible-vault create vars/vault.yml --vault-password-file .vault_pass
```

Content of `vars/vault.yml`:

```yaml
---
# Database credentials
vault_db_password: "SuperSecureDBPassword123!"

# Application secrets
vault_jwt_secret: "jwt-secret-key-change-in-production"
vault_api_key: "api-key-for-external-services"
vault_session_secret: "session-secret-for-cookies"

# SSL key passphrase
vault_ssl_key_passphrase: "ssl-key-passphrase-here"

# Admin credentials
vault_admin_username: "admin"
vault_admin_password: "Admin$ecureP@ssw0rd"
vault_admin_email: "admin@example.com"
```

#### Step 3: Reference Vault Variables in Tasks

Edit `tasks/main.yml`:

```yaml
---
- name: Include vault variables
  include_vars: vault.yml
  no_log: true

- name: Create application user
  user:
    name: "{{ app_user }}"
    group: "{{ app_group }}"
    create_home: yes
    shell: /bin/bash
    system: yes

- name: Configure database connection
  template:
    src: database.conf.j2
    dest: "/etc/{{ app_name }}/database.conf"
    owner: "{{ app_user }}"
    group: "{{ app_group }}"
    mode: '0600'
  no_log: true

- name: Configure application secrets
  template:
    src: secrets.env.j2
    dest: "/etc/{{ app_name }}/secrets.env"
    owner: "{{ app_user }}"
    group: "{{ app_group }}"
    mode: '0600'
  no_log: true
  notify: restart application

- name: Install SSL certificate
  copy:
    content: "{{ vault_ssl_cert }}"
    dest: "{{ ssl_cert_path }}"
    owner: root
    group: root
    mode: '0644'
  when: ssl_enabled
  no_log: true

- name: Install SSL private key
  copy:
    content: "{{ vault_ssl_key }}"
    dest: "{{ ssl_key_path }}"
    owner: root
    group: root
    mode: '0600'
  when: ssl_enabled
  no_log: true
```

Create `templates/database.conf.j2`:

```jinja2
# Database Configuration - DO NOT COMMIT THIS FILE
host={{ db_host }}
port={{ db_port }}
database={{ db_name }}
user={{ db_user }}
password={{ vault_db_password }}
sslmode=require
```

Create `templates/secrets.env.j2`:

```jinja2
# Application Secrets - DO NOT COMMIT THIS FILE
JWT_SECRET={{ vault_jwt_secret }}
API_KEY={{ vault_api_key }}
SESSION_SECRET={{ vault_session_secret }}
DB_PASSWORD={{ vault_db_password }}
ADMIN_USERNAME={{ vault_admin_username }}
ADMIN_PASSWORD={{ vault_admin_password }}
ADMIN_EMAIL={{ vault_admin_email }}
```

#### Step 4: Use Vault in Playbooks

Create `deploy-secure.yml`:

```yaml
---
- name: Deploy Secure Application
  hosts: production
  become: yes
  
  vars_files:
    - vars/vault.yml
  
  vars:
    ansible_vault_password_file: .vault_pass
  
  roles:
    - role: secure-webapp
      vars:
        db_password: "{{ vault_db_password }}"
        jwt_secret: "{{ vault_jwt_secret }}"
        api_key: "{{ vault_api_key }}"
  
  tasks:
    - name: Display non-sensitive info
      debug:
        msg: "Application {{ app_name }} deployed successfully"
    
    # Never display sensitive data
    - name: Verify secrets are loaded
      assert:
        that:
          - vault_db_password is defined
          - vault_jwt_secret is defined
        fail_msg: "Vault variables not loaded"
      no_log: true
```

#### Step 5: Vault Management Commands

```bash
# View encrypted file
ansible-vault view vars/vault.yml --vault-password-file .vault_pass

# Edit encrypted file
ansible-vault edit vars/vault.yml --vault-password-file .vault_pass

# Change vault password
ansible-vault rekey vars/vault.yml --vault-password-file .vault_pass

# Encrypt existing file
ansible-vault encrypt vars/secrets.yml --vault-password-file .vault_pass

# Decrypt file (for troubleshooting only)
ansible-vault decrypt vars/vault.yml --vault-password-file .vault_pass

# Run playbook with vault
ansible-playbook deploy-secure.yml --vault-password-file .vault_pass
```

#### Step 6: Molecule Testing with Vault

Edit `molecule/default/molecule.yml`:

```yaml
---
provisioner:
  name: ansible
  env:
    ANSIBLE_VAULT_PASSWORD_FILE: ${MOLECULE_PROJECT_DIRECTORY}/.vault_pass
  inventory:
    host_vars:
      instance:
        # Use test values, not production secrets
        vault_db_password: "test_password"
        vault_jwt_secret: "test_jwt_secret"
        vault_api_key: "test_api_key"
```

### 🔧 Part B: Security Scanning

#### Step 7: Add ansible-lint Security Rules

Create `.ansible-lint`:

```yaml
---
exclude_paths:
  - .cache/
  - .github/
  - molecule/

skip_list:
  - yaml[line-length]

warn_list:
  - no-changed-when
  - command-instead-of-module

# Security-focused rules
enable_list:
  - no-log-password
  - risky-file-permissions
  - risky-shell-pipe
```

Run security scan:

```bash
ansible-lint .

# Fix issues automatically where possible
ansible-lint --fix .
```

#### Step 8: Add Role Security Checklist

Create `SECURITY.md`:

```markdown
# Security Checklist

## Credentials Management
- [ ] All passwords stored in Ansible Vault
- [ ] No hardcoded credentials in code
- [ ] `.vault_pass` in `.gitignore`
- [ ] Separate vault files for different environments

## File Permissions
- [ ] Sensitive files have mode 0600
- [ ] Application runs as non-root user
- [ ] Proper ownership on all config files

## Network Security
- [ ] Firewall configured (UFW/iptables)
- [ ] Only required ports open
- [ ] fail2ban enabled
- [ ] SSH key-only authentication

## SSL/TLS
- [ ] SSL/TLS enabled for all services
- [ ] Valid certificates
- [ ] Strong cipher suites
- [ ] HSTS headers configured

## Application Security
- [ ] Latest security patches applied
- [ ] Security headers configured
- [ ] Input validation enabled
- [ ] Rate limiting implemented

## Logging & Monitoring
- [ ] Centralized logging configured
- [ ] Security events logged
- [ ] Log rotation configured
- [ ] Monitoring alerts set up

## Testing
- [ ] Security tests in Molecule verify
- [ ] ansible-lint passing
- [ ] No secrets in git history
```

### ✅ Expected Results

1. ✅ All sensitive data encrypted with Vault
2. ✅ Secure file permissions
3. ✅ No secrets exposed in logs
4. ✅ Security scanning passing
5. ✅ Production-ready security configuration

### 🎓 Learning Points

- ✅ Ansible Vault usage
- ✅ Secrets management
- ✅ Security best practices
- ✅ ansible-lint security rules
- ✅ Secure file handling

---

## Lab 13: CI/CD Pipeline with GitHub Actions

### 🎯 Objective

Create complete CI/CD pipeline for role development and deployment.

### 🔧 Steps

#### Step 1: GitHub Actions Workflow for Testing

Create `.github/workflows/ci.yml`:

```yaml
---
name: CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  lint:
    name: Lint
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.10'
      
      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install ansible ansible-lint yamllint
      
      - name: Run yaml-lint
        run: yamllint .
      
      - name: Run ansible-lint
        run: ansible-lint .

  molecule:
    name: Molecule Test
    runs-on: ubuntu-latest
    needs: lint
    strategy:
      matrix:
        distro:
          - ubuntu2004
          - ubuntu2204
          - debian11
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.10'
      
      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install molecule[docker] ansible-lint
      
      - name: Run Molecule tests
        run: molecule test
        env:
          PY_COLORS: '1'
          ANSIBLE_FORCE_COLOR: '1'
          MOLECULE_DISTRO: ${{ matrix.distro }}

  security:
    name: Security Scan
    runs-on: ubuntu-latest
    needs: lint
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      
      - name: Run Trivy security scanner
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'fs'
          scan-ref: '.'
          format: 'sarif'
          output: 'trivy-results.sarif'
      
      - name: Upload Trivy results to GitHub Security
        uses: github/codeql-action/upload-sarif@v2
        with:
          sarif_file: 'trivy-results.sarif'
```

#### Step 2: Auto-Release Workflow

Create `.github/workflows/release.yml`:

```yaml
---
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    name: Create Release
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      
      - name: Get tag version
        id: get_version
        run: echo "VERSION=${GITHUB_REF#refs/tags/v}" >> $GITHUB_OUTPUT
      
      - name: Create Release
        uses: actions/create-release@v1
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          tag_name: ${{ github.ref }}
          release_name: Release ${{ steps.get_version.outputs.VERSION }}
          draft: false
          prerelease: false
      
      - name: Publish to Ansible Galaxy
        uses: artis3n/ansible_galaxy_collection@v2
        with:
          api_key: ${{ secrets.GALAXY_API_KEY }}
          galaxy_version: ${{ steps.get_version.outputs.VERSION }}
```

#### Step 3: Setup GitHub Secrets

1. Go to GitHub repository → Settings → Secrets and variables → Actions
2. Add secrets:
   - `GALAXY_API_KEY`: Your Ansible Galaxy API token
   - `VAULT_PASSWORD`: Vault password for CI/CD

#### Step 4: Deploy Workflow

Create `.github/workflows/deploy.yml`:

```yaml
---
name: Deploy to Production

on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to deploy to'
        required: true
        default: 'staging'
        type: choice
        options:
          - staging
          - production

jobs:
  deploy:
    name: Deploy Application
    runs-on: ubuntu-latest
    environment: ${{ github.event.inputs.environment }}
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.10'
      
      - name: Install Ansible
        run: |
          python -m pip install --upgrade pip
          pip install ansible
      
      - name: Configure SSH
        run: |
          mkdir -p ~/.ssh
          echo "${{ secrets.SSH_PRIVATE_KEY }}" > ~/.ssh/id_rsa
          chmod 600 ~/.ssh/id_rsa
          ssh-keyscan -H ${{ secrets.DEPLOY_HOST }} >> ~/.ssh/known_hosts
      
      - name: Create vault password file
        run: |
          echo "${{ secrets.VAULT_PASSWORD }}" > .vault_pass
          chmod 600 .vault_pass
      
      - name: Run Ansible Playbook
        run: |
          ansible-playbook -i inventory/${{ github.event.inputs.environment }}.ini \
            deploy.yml \
            --vault-password-file .vault_pass
      
      - name: Verify deployment
        run: |
          ansible-playbook -i inventory/${{ github.event.inputs.environment }}.ini \
            verify.yml
      
      - name: Cleanup
        if: always()
        run: |
          rm -f .vault_pass
          rm -f ~/.ssh/id_rsa
```

### ✅ Expected Results

1. ✅ Automated testing on every push
2. ✅ Multi-platform testing matrix
3. ✅ Security scanning integrated
4. ✅ Auto-publish to Galaxy on tags
5. ✅ Production deployment workflow

### 🎓 Learning Points

- ✅ GitHub Actions workflows
- ✅ CI/CD pipelines
- ✅ Automated testing
- ✅ Security scanning
- ✅ Production deployment automation

---

## 📝 Advanced Practice Exercises

### Exercise 1: Build Complete LEMP Stack on OpenStack

**Requirements:**
1. Create role that deploys full LEMP (Linux, Nginx, MySQL, PHP) stack
2. Test with Molecule on OpenStack instance
3. Include security hardening
4. Use Vault for all credentials
5. Add health checks and monitoring
6. Publish to Galaxy

**Success Criteria:**
- ✅ All services running and integrated
- ✅ Security scan passing
- ✅ Automated tests passing
- ✅ Published to Galaxy with documentation

### Exercise 2: Database Replication Role

**Requirements:**
1. PostgreSQL primary-replica setup
2. Automatic failover configuration
3. Backup and restore procedures
4. Monitoring and alerting
5. Test on multiple instances

### Exercise 3: Kubernetes Deployment Role

**Requirements:**
1. Deploy K8s cluster
2. Configure networking
3. Set up ingress controller
4. Deploy sample application
5. Implement blue-green deployment

---

## 🎯 Summary

**Advanced Skills Mastered:**

✅ Complex role dependencies  
✅ OpenStack integration testing  
✅ Security hardening and Vault  
✅ CI/CD pipelines  
✅ Production deployment strategies  
✅ Role collections  
✅ Advanced Molecule scenarios  

**Production Ready:**
- ✅ Security best practices implemented
- ✅ Automated testing and deployment
- ✅ Comprehensive documentation
- ✅ Community contribution ready

---

**🎉 Congratulations! You're now an Ansible Roles expert ready for production!**
