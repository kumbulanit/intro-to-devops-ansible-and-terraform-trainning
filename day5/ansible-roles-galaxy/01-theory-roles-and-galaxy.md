# 📚 Ansible Roles and Galaxy - Complete Theory Guide

## 📖 Table of Contents
1. [Introduction to Ansible Roles](#introduction)
2. [Role Structure and Anatomy](#role-structure)
3. [Building Ansible Roles](#building-roles)
4. [Role Testing with Molecule](#molecule-testing)
5. [Ansible Galaxy Overview](#ansible-galaxy)
6. [Publishing to Galaxy](#publishing)
7. [High Availability with Galaxy](#high-availability)
8. [Best Practices](#best-practices)

---

## 🎯 Introduction to Ansible Roles {#introduction}

### What are Ansible Roles?

**Ansible Roles** are reusable, modular units of organization that group related tasks, variables, files, templates, and handlers together. They promote:

- **Code Reusability**: Write once, use everywhere
- **Organization**: Clean, structured code
- **Maintainability**: Easy to update and debug
- **Sharing**: Distribute via Ansible Galaxy
- **Modularity**: Break complex playbooks into manageable pieces

### Why Use Roles?

**Without Roles (Monolithic Playbook):**
```yaml
---
- name: Setup Web Server
  hosts: webservers
  tasks:
    - name: Install Apache
      apt: name=apache2 state=present
    - name: Configure Apache
      template: src=apache.conf.j2 dest=/etc/apache2/apache2.conf
    - name: Start Apache
      service: name=apache2 state=started
    # 100+ more tasks...
```

**With Roles (Clean & Organized):**
```yaml
---
- name: Setup Web Server
  hosts: webservers
  roles:
    - apache
    - php
    - mysql
```

### Real-World Analogy

Think of roles like **recipes in a cookbook**:
- Each recipe (role) is independent
- Recipes can be combined to make a full meal (playbook)
- Recipes can be shared with others (Galaxy)
- Each recipe has ingredients (variables), steps (tasks), and tools (handlers)

---

## 🏗️ Role Structure and Anatomy {#role-structure}

### Standard Role Directory Structure

```
my-role/
├── README.md                 # Role documentation
├── meta/
│   └── main.yml             # Role metadata (dependencies, Galaxy info)
├── defaults/
│   └── main.yml             # Default variables (lowest priority)
├── vars/
│   └── main.yml             # Role variables (high priority)
├── tasks/
│   └── main.yml             # Main task list
├── handlers/
│   └── main.yml             # Handlers (triggered by notify)
├── templates/
│   └── config.j2            # Jinja2 templates
├── files/
│   └── static-file.conf     # Static files to copy
├── tests/
│   ├── inventory            # Test inventory
│   └── test.yml             # Test playbook
└── molecule/                # Molecule test scenarios
    └── default/
        ├── molecule.yml     # Molecule configuration
        ├── converge.yml     # Test playbook
        └── verify.yml       # Verification tests
```

### Directory Deep Dive

#### 1. **tasks/** - The Heart of the Role
Contains the main logic of what the role does.

**Example:** `tasks/main.yml`
```yaml
---
# Main task file for webserver role
- name: Include OS-specific variables
  include_vars: "{{ ansible_os_family }}.yml"

- name: Install web server packages
  package:
    name: "{{ webserver_packages }}"
    state: present

- name: Configure web server
  template:
    src: webserver.conf.j2
    dest: "{{ webserver_config_path }}"
  notify: restart webserver

- name: Ensure webserver is running
  service:
    name: "{{ webserver_service }}"
    state: started
    enabled: yes
```

**Task Organization Patterns:**

**Pattern 1: Single main.yml**
```
tasks/
└── main.yml  # All tasks in one file
```

**Pattern 2: Modular tasks**
```
tasks/
├── main.yml      # Includes other task files
├── install.yml   # Installation tasks
├── configure.yml # Configuration tasks
└── security.yml  # Security hardening
```

**main.yml with includes:**
```yaml
---
- import_tasks: install.yml
- import_tasks: configure.yml
- import_tasks: security.yml
```

#### 2. **defaults/** - Default Variables
Lowest priority variables, easily overridden.

**Example:** `defaults/main.yml`
```yaml
---
# Default variables for webserver role
webserver_port: 80
webserver_root: /var/www/html
webserver_user: www-data
webserver_max_connections: 150
webserver_ssl_enabled: false

# Package names (can be overridden per OS)
webserver_packages:
  - apache2
  - apache2-utils
```

#### 3. **vars/** - Role Variables
Higher priority variables, harder to override.

**Example:** `vars/main.yml`
```yaml
---
# Variables for webserver role (high priority)
webserver_service: apache2
webserver_config_path: /etc/apache2/apache2.conf
webserver_log_dir: /var/log/apache2
```

**OS-Specific Variables:**
```yaml
# vars/Debian.yml
webserver_packages:
  - apache2
  - apache2-utils
webserver_service: apache2

# vars/RedHat.yml
webserver_packages:
  - httpd
  - httpd-tools
webserver_service: httpd
```

#### 4. **handlers/** - Event Handlers
Triggered by `notify` from tasks, run at the end.

**Example:** `handlers/main.yml`
```yaml
---
# Handlers for webserver role
- name: restart webserver
  service:
    name: "{{ webserver_service }}"
    state: restarted

- name: reload webserver
  service:
    name: "{{ webserver_service }}"
    state: reloaded

- name: check webserver config
  command: "{{ webserver_config_test_command }}"
  changed_when: false
```

**Handler Usage in Tasks:**
```yaml
- name: Update configuration
  template:
    src: config.j2
    dest: /etc/webserver/config.conf
  notify: 
    - check webserver config
    - reload webserver
```

#### 5. **templates/** - Jinja2 Templates
Dynamic configuration files.

**Example:** `templates/webserver.conf.j2`
```jinja2
# Apache Configuration
# Managed by Ansible - Do not edit manually

ServerRoot "/etc/apache2"
Listen {{ webserver_port }}

User {{ webserver_user }}
Group {{ webserver_user }}

ServerAdmin {{ webserver_admin_email | default('admin@localhost') }}

<Directory {{ webserver_root }}>
    Options Indexes FollowSymLinks
    AllowOverride None
    Require all granted
</Directory>

{% if webserver_ssl_enabled %}
# SSL Configuration
SSLEngine on
SSLCertificateFile {{ ssl_cert_path }}
SSLCertificateKeyFile {{ ssl_key_path }}
{% endif %}

# Logging
ErrorLog ${APACHE_LOG_DIR}/error.log
CustomLog ${APACHE_LOG_DIR}/access.log combined

# Performance tuning
MaxRequestWorkers {{ webserver_max_connections }}
KeepAlive On
KeepAliveTimeout 5
```

#### 6. **files/** - Static Files
Files copied as-is without templating.

**Example Usage:**
```yaml
- name: Copy static HTML file
  copy:
    src: index.html
    dest: "{{ webserver_root }}/index.html"
    owner: "{{ webserver_user }}"
    mode: '0644'
```

#### 7. **meta/** - Role Metadata
Dependencies and Galaxy information.

**Example:** `meta/main.yml`
```yaml
---
galaxy_info:
  author: Your Name
  description: Production-ready web server role
  company: Your Company
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
        - bookworm
    - name: EL
      versions:
        - 8
        - 9
  
  galaxy_tags:
    - web
    - apache
    - nginx
    - webserver
    - http

dependencies:
  - role: common
    vars:
      common_firewall_enabled: true
  - role: ssl-certificates
    when: webserver_ssl_enabled
```

#### 8. **tests/** - Role Testing
Simple test playbook and inventory.

**Example:** `tests/test.yml`
```yaml
---
- hosts: localhost
  remote_user: root
  roles:
    - webserver
```

---

## 🔨 Building Ansible Roles {#building-roles}

### Method 1: Using ansible-galaxy init

**Create a new role:**
```bash
# Create role with standard structure
ansible-galaxy init my-webserver

# Create role in specific directory
ansible-galaxy init --init-path roles/ my-webserver

# Create role with custom structure
ansible-galaxy init my-webserver --role-skeleton=/path/to/skeleton
```

**Output:**
```
my-webserver/
├── README.md
├── defaults/
│   └── main.yml
├── files/
├── handlers/
│   └── main.yml
├── meta/
│   └── main.yml
├── tasks/
│   └── main.yml
├── templates/
├── tests/
│   ├── inventory
│   └── test.yml
└── vars/
    └── main.yml
```

### Method 2: Manual Creation

```bash
# Create directory structure manually
mkdir -p my-role/{tasks,handlers,templates,files,vars,defaults,meta,tests}
touch my-role/{tasks,handlers,vars,defaults,meta}/main.yml
touch my-role/tests/test.yml
touch my-role/README.md
```

### Building a Real Role: PostgreSQL Example

**Directory Structure:**
```
postgresql/
├── README.md
├── defaults/
│   └── main.yml
├── files/
│   └── pg_hba.conf
├── handlers/
│   └── main.yml
├── meta/
│   └── main.yml
├── tasks/
│   ├── main.yml
│   ├── install.yml
│   ├── configure.yml
│   └── databases.yml
├── templates/
│   └── postgresql.conf.j2
└── vars/
    ├── main.yml
    ├── Debian.yml
    └── RedHat.yml
```

**defaults/main.yml:**
```yaml
---
# PostgreSQL version
postgresql_version: 14

# PostgreSQL configuration
postgresql_port: 5432
postgresql_listen_addresses: 'localhost'
postgresql_max_connections: 100
postgresql_shared_buffers: '128MB'

# Authentication
postgresql_auth_method: md5

# Databases to create
postgresql_databases:
  - name: myapp
    owner: myapp_user

# Users to create
postgresql_users:
  - name: myapp_user
    password: changeme
    priv: "myapp:ALL"
```

**tasks/main.yml:**
```yaml
---
- name: Include OS-specific variables
  include_vars: "{{ ansible_os_family }}.yml"

- name: Include installation tasks
  import_tasks: install.yml

- name: Include configuration tasks
  import_tasks: configure.yml

- name: Include database creation tasks
  import_tasks: databases.yml
  when: postgresql_databases is defined
```

**tasks/install.yml:**
```yaml
---
- name: Install PostgreSQL repository (Ubuntu)
  apt:
    deb: "https://apt.postgresql.org/pub/repos/apt/pool/main/p/postgresql-common/\
          postgresql-common_{{ postgresql_repo_version }}_all.deb"
  when: ansible_distribution == "Ubuntu"

- name: Install PostgreSQL packages
  package:
    name: "{{ postgresql_packages }}"
    state: present

- name: Ensure PostgreSQL is started and enabled
  service:
    name: "{{ postgresql_service }}"
    state: started
    enabled: yes
```

**tasks/configure.yml:**
```yaml
---
- name: Configure PostgreSQL
  template:
    src: postgresql.conf.j2
    dest: "{{ postgresql_config_path }}/postgresql.conf"
    owner: postgres
    group: postgres
    mode: '0644'
  notify: restart postgresql

- name: Configure PostgreSQL authentication
  template:
    src: pg_hba.conf.j2
    dest: "{{ postgresql_config_path }}/pg_hba.conf"
    owner: postgres
    group: postgres
    mode: '0640'
  notify: restart postgresql
```

**handlers/main.yml:**
```yaml
---
- name: restart postgresql
  service:
    name: "{{ postgresql_service }}"
    state: restarted

- name: reload postgresql
  service:
    name: "{{ postgresql_service }}"
    state: reloaded
```

### Role Variable Precedence

From **lowest** to **highest** priority:

1. role defaults (`defaults/main.yml`)
2. inventory file or script group vars
3. inventory group_vars/all
4. playbook group_vars/all
5. inventory group_vars/*
6. playbook group_vars/*
7. inventory file or script host vars
8. inventory host_vars/*
9. playbook host_vars/*
10. host facts / cached set_facts
11. play vars
12. play vars_prompt
13. play vars_files
14. role vars (`vars/main.yml`)
15. block vars
16. task vars
17. include_vars
18. set_facts / registered vars
19. role (and include_role) params
20. include params
21. extra vars (CLI `-e`)

**Example Showing Precedence:**
```yaml
# defaults/main.yml (Priority: 1 - Lowest)
app_port: 8080

# vars/main.yml (Priority: 14 - Higher)
app_port: 8000

# Playbook (Priority: 11)
- hosts: web
  vars:
    app_port: 9000
  roles:
    - my-app

# Extra vars (Priority: 21 - Highest)
ansible-playbook site.yml -e "app_port=7000"

# Final value used: 7000
```

---

## 🧪 Role Testing with Molecule {#molecule-testing}

### What is Molecule?

**Molecule** is a testing framework for Ansible roles that helps you:
- Test roles in isolation
- Test across multiple platforms
- Verify role idempotency
- Perform integration testing
- CI/CD pipeline integration

### Molecule Workflow

```
┌─────────────────────────────────────────────────────────┐
│  1. Create    → Create test infrastructure (Docker)     │
│  2. Converge  → Run the role                            │
│  3. Idempotence → Run again, ensure no changes         │
│  4. Verify    → Run verification tests                  │
│  5. Destroy   → Clean up test infrastructure            │
└─────────────────────────────────────────────────────────┘
```

### Installing Molecule

```bash
# Install Molecule with Docker driver
pip3 install molecule[docker]

# Or with multiple drivers
pip3 install molecule[docker,vagrant]

# Install additional dependencies
pip3 install molecule-docker ansible-lint yamllint
```

### Initializing Molecule in a Role

```bash
# In your role directory
cd my-role/

# Initialize Molecule with Docker driver
molecule init scenario default --driver-name docker

# Initialize with specific platform
molecule init scenario default --driver-name docker \
  --verifier-name testinfra
```

**Generated Structure:**
```
my-role/
└── molecule/
    └── default/
        ├── molecule.yml       # Molecule configuration
        ├── converge.yml       # Playbook to test the role
        ├── verify.yml         # Verification tasks
        └── INSTALL.rst        # Installation instructions
```

### Molecule Configuration

**molecule/default/molecule.yml:**
```yaml
---
dependency:
  name: galaxy
driver:
  name: docker
platforms:
  - name: ubuntu-focal
    image: geerlingguy/docker-ubuntu2004-ansible:latest
    pre_build_image: true
    privileged: true
    volumes:
      - /sys/fs/cgroup:/sys/fs/cgroup:ro
    command: /lib/systemd/systemd
  
  - name: debian-bullseye
    image: geerlingguy/docker-debian11-ansible:latest
    pre_build_image: true
    privileged: true
    volumes:
      - /sys/fs/cgroup:/sys/fs/cgroup:ro
    command: /lib/systemd/systemd

provisioner:
  name: ansible
  config_options:
    defaults:
      callbacks_enabled: profile_tasks
  playbooks:
    converge: converge.yml
  inventory:
    host_vars:
      ubuntu-focal:
        webserver_port: 8080
      debian-bullseye:
        webserver_port: 8081

verifier:
  name: ansible

lint: |
  set -e
  yamllint .
  ansible-lint .
```

**molecule/default/converge.yml:**
```yaml
---
- name: Converge
  hosts: all
  become: true
  
  pre_tasks:
    - name: Update apt cache (Debian)
      apt:
        update_cache: yes
      when: ansible_os_family == 'Debian'
  
  roles:
    - role: my-webserver
```

**molecule/default/verify.yml:**
```yaml
---
- name: Verify
  hosts: all
  gather_facts: false
  
  tasks:
    - name: Check if web server is installed
      package:
        name: "{{ webserver_package_name }}"
        state: present
      check_mode: yes
      register: pkg_check
      failed_when: pkg_check.changed

    - name: Check if web server is running
      service:
        name: "{{ webserver_service }}"
        state: started
      check_mode: yes
      register: svc_check
      failed_when: svc_check.changed

    - name: Test web server response
      uri:
        url: "http://localhost:{{ webserver_port }}"
        status_code: 200
      register: http_response
      failed_when: http_response.status != 200

    - name: Verify configuration file exists
      stat:
        path: "{{ webserver_config_path }}"
      register: config_file
      failed_when: not config_file.stat.exists
```

### Running Molecule Tests

```bash
# Full test cycle
molecule test

# Individual steps
molecule create      # Create test infrastructure
molecule converge    # Run the role
molecule verify      # Run verification tests
molecule destroy     # Clean up

# Test idempotency
molecule idempotence

# Test with specific scenario
molecule test -s custom-scenario

# Debug mode
molecule --debug test

# Keep infrastructure after test
molecule test --destroy=never
```

### Molecule Test Output Example

```
--> Test matrix
    
└── default
    ├── dependency
    ├── lint
    ├── cleanup
    ├── destroy
    ├── syntax
    ├── create
    ├── prepare
    ├── converge
    ├── idempotence
    ├── side_effect
    ├── verify
    ├── cleanup
    └── destroy

--> Scenario: 'default'
--> Action: 'dependency'
Skipping, missing the requirements file.

--> Action: 'lint'
--> Lint is enabled.
--> Running yamllint...
yamllint .
--> Running ansible-lint...
ansible-lint .

--> Action: 'create'
    PLAY [Create] **********************************************************
    
    TASK [Create molecule instance(s)] ************************************
    changed: [localhost] => (item=ubuntu-focal)
    
    PLAY RECAP *************************************************************
    localhost                  : ok=5    changed=4    unreachable=0    failed=0

--> Action: 'converge'
    PLAY [Converge] ********************************************************
    
    TASK [Gathering Facts] *************************************************
    ok: [ubuntu-focal]
    
    TASK [Include my-webserver] ********************************************
    
    PLAY RECAP *************************************************************
    ubuntu-focal              : ok=15   changed=8    unreachable=0    failed=0

--> Action: 'idempotence'
    PLAY [Converge] ********************************************************
    
    PLAY RECAP *************************************************************
    ubuntu-focal              : ok=15   changed=0    unreachable=0    failed=0

Idempotence completed successfully.

--> Action: 'verify'
    PLAY [Verify] **********************************************************
    
    TASK [Check if web server is running] **********************************
    ok: [ubuntu-focal]
    
    PLAY RECAP *************************************************************
    ubuntu-focal              : ok=4    changed=0    unreachable=0    failed=0
```

### Advanced Molecule Features

#### Multi-Platform Testing

```yaml
# molecule/default/molecule.yml
platforms:
  - name: ubuntu-20
    image: ubuntu:20.04
  - name: ubuntu-22
    image: ubuntu:22.04
  - name: centos-8
    image: centos:8
  - name: debian-11
    image: debian:11
```

#### Custom Scenarios

```bash
# Create production scenario
molecule init scenario production --driver-name docker

# File structure
molecule/
├── default/
│   ├── molecule.yml
│   └── converge.yml
└── production/
    ├── molecule.yml
    └── converge.yml

# Run specific scenario
molecule test -s production
```

#### Integration with CI/CD

**.gitlab-ci.yml:**
```yaml
molecule_test:
  stage: test
  image: python:3.9
  before_script:
    - pip install molecule[docker] ansible-lint yamllint
  script:
    - molecule test
  only:
    - merge_requests
    - main
```

**.github/workflows/molecule.yml:**
```yaml
name: Molecule Test
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: actions/setup-python@v2
        with:
          python-version: '3.9'
      - name: Install dependencies
        run: |
          pip install molecule[docker] ansible-lint yamllint
      - name: Run Molecule tests
        run: molecule test
```

---

## 🌟 Ansible Galaxy Overview {#ansible-galaxy}

### What is Ansible Galaxy?

**Ansible Galaxy** (https://galaxy.ansible.com) is:
- **Community Hub**: Repository of Ansible roles
- **Role Distribution**: Easy way to share roles
- **Dependency Management**: Install roles and collections
- **Quality Control**: Community ratings and reviews

### Galaxy vs GitHub

| Aspect | Ansible Galaxy | GitHub |
|--------|----------------|--------|
| **Purpose** | Role distribution | Source code hosting |
| **Discovery** | Easy role search | Code repositories |
| **Installation** | `ansible-galaxy install` | Clone manually |
| **Dependencies** | Automatic resolution | Manual management |
| **Versioning** | Semantic versioning | Git tags/branches |
| **Community** | Ansible-focused | General development |

### Galaxy Command Line Interface

```bash
# Search for roles
ansible-galaxy search apache
ansible-galaxy search --author geerlingguy

# Install a role
ansible-galaxy install geerlingguy.apache

# Install specific version
ansible-galaxy install geerlingguy.apache,2.1.0

# Install from requirements file
ansible-galaxy install -r requirements.yml

# List installed roles
ansible-galaxy list

# Remove a role
ansible-galaxy remove geerlingguy.apache

# Get role info
ansible-galaxy info geerlingguy.apache
```

### requirements.yml File

**Basic requirements.yml:**
```yaml
---
# Install from Galaxy
- name: geerlingguy.apache
  version: 2.1.0

- name: geerlingguy.mysql
  version: 3.3.2

# Install from GitHub
- src: https://github.com/username/my-role
  name: my-custom-role
  version: master

# Install from Git with specific version
- src: git+https://github.com/username/another-role.git
  version: v1.2.3
  name: another-role

# Install from tarball
- src: https://example.com/roles/my-role.tar.gz
  name: downloaded-role
```

**Advanced requirements.yml:**
```yaml
---
roles:
  # Production roles with pinned versions
  - name: geerlingguy.apache
    version: "2.1.0"
  
  - name: geerlingguy.mysql
    version: "3.3.2"
  
  # Development role from branch
  - src: https://github.com/mycompany/internal-role
    name: internal-role
    version: develop
    scm: git

collections:
  # Also manage collections
  - name: community.general
    version: ">=3.0.0"
  
  - name: ansible.posix
    version: "1.4.0"
```

**Installing from requirements:**
```bash
# Install all roles
ansible-galaxy install -r requirements.yml

# Install to specific directory
ansible-galaxy install -r requirements.yml -p ./roles/

# Force reinstall
ansible-galaxy install -r requirements.yml --force
```

### Galaxy Role Quality Indicators

1. **Quality Score**: Calculated from:
   - Downloads
   - Stars
   - Watchers
   - Forks

2. **Documentation**: README completeness

3. **Testing**: Presence of tests

4. **Maintenance**: Last updated date

5. **Community Feedback**: Issues, PRs, discussions

---

## 📤 Publishing to Galaxy {#publishing}

### Preparation Checklist

Before publishing a role to Galaxy:

- [ ] Complete `meta/main.yml` with Galaxy info
- [ ] Write comprehensive `README.md`
- [ ] Add `LICENSE` file
- [ ] Create meaningful `.gitignore`
- [ ] Write tests (Molecule preferred)
- [ ] Add examples in `README.md`
- [ ] Version your role (Git tags)
- [ ] Test on multiple platforms

### Step 1: Create Galaxy Account

1. Go to https://galaxy.ansible.com
2. Click "Sign In" → Use GitHub account
3. Authorize Ansible Galaxy
4. Your roles will sync from GitHub

### Step 2: Prepare meta/main.yml

**Complete meta/main.yml:**
```yaml
---
galaxy_info:
  author: John Doe
  description: Production-ready PostgreSQL role for Ubuntu and Debian
  company: MyCompany Inc.
  
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
        - bookworm
  
  galaxy_tags:
    - database
    - postgresql
    - postgres
    - sql
    - rdbms
    - production
    - ubuntu
    - debian

dependencies: []
  # Example with dependencies:
  # - role: common
  # - role: firewall
  #   vars:
  #     firewall_allowed_ports:
  #       - 5432
```

### Step 3: Create Comprehensive README

**README.md Template:**
```markdown
# Ansible Role: PostgreSQL

[![CI](https://github.com/username/ansible-role-postgresql/workflows/CI/badge.svg)](https://github.com/username/ansible-role-postgresql/actions)
[![Ansible Galaxy](https://img.shields.io/badge/galaxy-username.postgresql-blue.svg)](https://galaxy.ansible.com/username/postgresql)

Installs and configures PostgreSQL on Ubuntu and Debian.

## Requirements

- Ansible 2.9 or higher
- Ubuntu 20.04/22.04 or Debian 11/12

## Role Variables

Available variables with default values (see `defaults/main.yml`):

```yaml
postgresql_version: 14
postgresql_port: 5432
postgresql_listen_addresses: 'localhost'
postgresql_max_connections: 100
```

See `defaults/main.yml` for full list.

## Dependencies

None.

## Example Playbook

```yaml
- hosts: database_servers
  become: yes
  roles:
    - role: username.postgresql
      vars:
        postgresql_port: 5432
        postgresql_databases:
          - name: myapp
        postgresql_users:
          - name: myapp_user
            password: secret
```

## Testing

This role includes Molecule tests:

```bash
pip install molecule[docker]
molecule test
```

## License

MIT

## Author Information

Created by [Your Name](https://github.com/username)
```

### Step 4: Push to GitHub

```bash
# Initialize git if needed
git init
git add .
git commit -m "Initial commit"

# Add remote
git remote add origin https://github.com/username/ansible-role-postgresql.git

# Push to GitHub
git branch -M main
git push -u origin main

# Create version tag
git tag 1.0.0
git push origin 1.0.0
```

### Step 5: Import to Galaxy

**Method 1: Automatic (Recommended)**
1. Go to https://galaxy.ansible.com/my-content/namespaces
2. Click "Add Content" → "Repository"
3. Select your GitHub repository
4. Galaxy will automatically import on new tags

**Method 2: Manual**
```bash
# Login to Galaxy
ansible-galaxy login

# Import role
ansible-galaxy import username ansible-role-postgresql
```

### Step 6: Configure Webhooks

Enable automatic imports on GitHub push:

1. In Galaxy, go to your role settings
2. Enable "Auto import on GitHub push"
3. GitHub webhook automatically configured

Now whenever you push a new tag:
```bash
git tag 1.0.1
git push origin 1.0.1
# Galaxy automatically imports new version
```

---

## 🚀 High Availability with Galaxy {#high-availability}

### Role Versioning Strategy

#### Semantic Versioning

Follow **SemVer** (MAJOR.MINOR.PATCH):

```
1.2.3
│ │ │
│ │ └─ PATCH: Bug fixes, no breaking changes
│ └─── MINOR: New features, backward compatible
└───── MAJOR: Breaking changes
```

**Examples:**
- `1.0.0` → `1.0.1`: Bug fix
- `1.0.1` → `1.1.0`: New feature added
- `1.1.0` → `2.0.0`: Breaking change (new required variable)

**Tagging strategy:**
```bash
# Bug fix
git tag 1.0.1
git push origin 1.0.1

# New feature
git tag 1.1.0
git push origin 1.1.0

# Breaking change
git tag 2.0.0
git push origin 2.0.0
```

### Managing Multiple Versions

**requirements.yml with version constraints:**
```yaml
---
roles:
  # Exact version
  - name: username.postgresql
    version: "1.0.0"
  
  # Version range (any 1.x version)
  - name: username.apache
    version: "~1.0"
  
  # Minimum version
  - name: username.nginx
    version: ">=2.0.0"
  
  # Maximum version
  - name: username.mysql
    version: "<=3.5.0"
  
  # Version range
  - name: username.redis
    version: ">=1.0.0,<2.0.0"
```

### Role Dependencies and Compatibility

**meta/main.yml with versioned dependencies:**
```yaml
dependencies:
  - role: username.common
    version: "1.2.0"
  
  - role: username.firewall
    version: ">=2.0.0"
    vars:
      firewall_allowed_ports:
        - 5432
  
  - role: username.ssl
    when: postgresql_ssl_enabled
    version: "~1.0"
```

### Maintaining Backward Compatibility

**Strategy 1: Deprecation Warnings**
```yaml
# tasks/main.yml
- name: Check for deprecated variables
  debug:
    msg: "WARNING: Variable 'old_var_name' is deprecated. Use 'new_var_name' instead."
  when: old_var_name is defined

- name: Use deprecated variable if new one not set
  set_fact:
    new_var_name: "{{ old_var_name }}"
  when: 
    - old_var_name is defined
    - new_var_name is not defined
```

**Strategy 2: Version-specific tasks**
```yaml
- name: Old configuration method (< 2.0)
  include_tasks: configure_legacy.yml
  when: role_version is version('2.0', '<')

- name: New configuration method (>= 2.0)
  include_tasks: configure_modern.yml
  when: role_version is version('2.0', '>=')
```

### Changelog Management

**CHANGELOG.md:**
```markdown
# Changelog

All notable changes to this project will be documented in this file.

## [2.0.0] - 2024-01-15

### Changed
- **BREAKING**: Renamed `db_port` to `postgresql_port`
- **BREAKING**: Changed default PostgreSQL version to 14

### Added
- Support for PostgreSQL 15
- New variable `postgresql_ssl_enabled`
- Molecule tests for multiple platforms

### Fixed
- Fixed issue with configuration permissions
- Resolved handler notification bug

## [1.2.1] - 2023-12-01

### Fixed
- Corrected package name for Debian 12

## [1.2.0] - 2023-11-15

### Added
- Support for Debian 12
- New variable `postgresql_max_connections`

## [1.1.0] - 2023-10-01

### Added
- Support for Ubuntu 22.04
- Automated backup configuration

## [1.0.0] - 2023-09-01

### Added
- Initial release
- PostgreSQL installation and configuration
- Support for Ubuntu 20.04 and Debian 11
```

---

## ✅ Best Practices {#best-practices}

### 1. Role Naming Conventions

**Good names:**
- `nginx`
- `postgresql`
- `java-openjdk`
- `app-deploy`

**Avoid:**
- `role1` (not descriptive)
- `my_awesome_role` (too casual)
- `server` (too generic)

**Galaxy naming:**
- GitHub: `ansible-role-nginx`
- Galaxy: `username.nginx`

### 2. Variable Naming

**Use prefixes to avoid conflicts:**
```yaml
# Bad (conflicts with other roles)
port: 8080
user: www-data

# Good (namespaced)
nginx_port: 8080
nginx_user: www-data
```

**Variable naming conventions:**
```yaml
# Boolean variables
nginx_ssl_enabled: true
nginx_cache_enabled: false

# Lists
nginx_modules:
  - ssl
  - gzip

# Dictionaries
nginx_sites:
  default:
    port: 80
    root: /var/www/html
```

### 3. Idempotency

**Ensure tasks can run multiple times safely:**

**Bad (not idempotent):**
```yaml
- name: Add line to config
  shell: echo "setting=value" >> /etc/config.conf
```

**Good (idempotent):**
```yaml
- name: Ensure setting in config
  lineinfile:
    path: /etc/config.conf
    line: "setting=value"
    state: present
```

### 4. Testing Strategy

```
Unit Tests (Molecule)
    ↓
Integration Tests
    ↓
Acceptance Tests
    ↓
Production
```

**Minimum tests:**
1. Package installation
2. Service running
3. Configuration file present
4. Service responding
5. Idempotency check

### 5. Documentation

**Essential documentation:**
- **README.md**: Usage, variables, examples
- **CHANGELOG.md**: Version history
- **LICENSE**: Legal terms
- **meta/main.yml**: Galaxy metadata
- **defaults/main.yml**: Commented variables

### 6. Security Practices

```yaml
# Don't hardcode secrets
bad_password: "supersecret123"

# Use variables with no_log
- name: Create database user
  postgresql_user:
    name: myuser
    password: "{{ db_password }}"
  no_log: true

# Use Ansible Vault
# In group_vars/all/vault.yml (encrypted)
vault_db_password: "encrypted_secret"

# Reference in defaults
db_password: "{{ vault_db_password }}"
```

### 7. Performance Optimization

```yaml
# Use cache for package facts
- name: Gather package facts
  package_facts:
  cache: yes

# Parallel execution
- name: Install multiple packages
  package:
    name:
      - package1
      - package2
      - package3
  async: 300
  poll: 5

# Conditional execution
- name: Configure service
  template:
    src: config.j2
    dest: /etc/service/config.conf
  when: configure_service | bool
  notify: restart service
```

### 8. Platform Independence

```yaml
# Use generic modules
- name: Install package (any OS)
  package:
    name: "{{ pkg_name }}"

# OS-specific variables
- name: Load OS-specific variables
  include_vars: "{{ ansible_os_family }}.yml"

# Conditional tasks
- name: Install Apache (Debian)
  apt:
    name: apache2
  when: ansible_os_family == "Debian"

- name: Install Apache (RedHat)
  yum:
    name: httpd
  when: ansible_os_family == "RedHat"
```

### 9. CI/CD Integration

**.github/workflows/ci.yml:**
```yaml
name: CI
on: [push, pull_request]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Run yamllint
        run: yamllint .
      - name: Run ansible-lint
        run: ansible-lint .
  
  molecule:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        distro:
          - ubuntu2004
          - ubuntu2204
          - debian11
    steps:
      - uses: actions/checkout@v2
      - name: Run Molecule tests
        run: molecule test
        env:
          MOLECULE_DISTRO: ${{ matrix.distro }}
```

### 10. Role Maintenance

**Regular maintenance checklist:**
- [ ] Update supported platform versions
- [ ] Test with latest Ansible version
- [ ] Update dependencies
- [ ] Review and close old issues
- [ ] Update documentation
- [ ] Check for security vulnerabilities
- [ ] Update examples
- [ ] Review and merge PRs

---

## 📚 Additional Resources

### Official Documentation
- [Ansible Roles Documentation](https://docs.ansible.com/ansible/latest/user_guide/playbooks_reuse_roles.html)
- [Ansible Galaxy Documentation](https://docs.ansible.com/ansible/latest/galaxy/user_guide.html)
- [Molecule Documentation](https://molecule.readthedocs.io/)

### Community Resources
- [Ansible Galaxy](https://galaxy.ansible.com)
- [Jeff Geerling's Roles](https://github.com/geerlingguy) (Best practices examples)
- [Ansible Community](https://www.ansible.com/community)

### Tools
- [ansible-lint](https://github.com/ansible/ansible-lint)
- [yamllint](https://github.com/adrienverge/yamllint)
- [pre-commit hooks](https://pre-commit.com/)

---

## 🎯 Summary

**Key Takeaways:**

1. **Roles are reusable units** that organize Ansible code
2. **Standard structure** promotes consistency
3. **Galaxy** enables sharing and community contributions
4. **Molecule** provides comprehensive testing
5. **Versioning** ensures stability and compatibility
6. **Best practices** make roles production-ready

**Next Steps:**
1. Build your first role
2. Test with Molecule
3. Publish to Galaxy
4. Contribute to community roles

---

**🎉 You're now ready to create professional Ansible roles!**
