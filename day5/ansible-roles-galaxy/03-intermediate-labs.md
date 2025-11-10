# 🎓 Ansible Roles - Intermediate Labs

## Lab Overview

These intermediate labs cover testing with Molecule, publishing to Galaxy, and GitHub integration. You'll learn professional role development workflows.

### 🖥️ Testing Environment Options

**IMPORTANT**: These labs can be completed with:

#### Option 1: Docker (Recommended for Molecule Labs)
- Faster iteration
- No cloud resources needed
- Ideal for testing framework
- Requires Docker installed locally

#### Option 2: OpenStack Instance
- Real infrastructure testing
- Tests against actual OS environment
- See **OPENSTACK-TESTING-GUIDE.md** for setup
- Use for integration testing

#### Option 3: Hybrid Approach (Best Practice)
- **Development/Unit Tests**: Use Docker with Molecule
- **Integration Tests**: Deploy to OpenStack instance
- **Production Validation**: Test on actual target environment

### 📝 Lab Environment Setup

```bash
# Create intermediate labs workspace
mkdir -p ~/ansible_training/day5/intermediate-labs
cd ~/ansible_training/day5/intermediate-labs

# For OpenStack testing, verify connection
ansible all -i ../labs/inventory.ini -m ping

# For Docker testing, verify Docker
docker --version
docker ps
```

---

## Lab 5: Introduction to Molecule Testing

### 🎯 Objective
Learn to test Ansible roles using Molecule with Docker driver, with optional OpenStack instance testing.

### 📋 Prerequisites
- ✅ Completed beginner labs
- ✅ Docker installed (`docker --version`)
- ✅ Python 3.6+ (`python3 --version`)
- ✅ (Optional) OpenStack instance accessible for integration tests

### ⏱️ Estimated Time
90 minutes

### 🧪 What You'll Learn
- Installing and configuring Molecule
- Writing test scenarios with Docker
- Creating verification playbooks
- Running tests locally and in CI/CD
- Testing against real OpenStack instances

### 🔧 Part A: Install and Setup Molecule

#### Step 1: Install Molecule and Dependencies

**What this does**: Installs Molecule testing framework with Docker driver for running tests in containers.

```bash
# Navigate to your working directory
cd ~/ansible_training/day5/intermediate-labs

# Install Molecule with Docker driver
pip3 install molecule[docker]

# Install additional tools for linting and Docker support
pip3 install ansible-lint yamllint molecule-docker

# Verify installations
molecule --version
docker --version
ansible-lint --version
```

**Expected output:**
```
molecule 5.1.0 using python 3.9
ansible: 2.14.3
...

Docker version 24.0.2, build cb74dfc

ansible-lint 6.14.3 using ansible 2.14.3
```

**If pip3 not found:**
```bash
# Install pip3 first
sudo apt install python3-pip   # Ubuntu/Debian
sudo yum install python3-pip   # RHEL/CentOS

# Or use Python module
python3 -m pip install --user molecule[docker]
```

**Troubleshooting:**
- **Error: "externally-managed-environment"**: Use `python3 -m pip install --user molecule[docker]`
- **Error: "docker: command not found"**: Install Docker from https://docs.docker.com/engine/install/
- **Permission denied**: Add user to docker group: `sudo usermod -aG docker $USER` (logout/login required)

#### Step 2: Create a New Role with Molecule

**What this does**: Creates a new Ansible role with Molecule testing framework integrated from the start.

```bash
# Navigate to roles directory
cd ~/ansible_training/day5/roles/

# Create role with Molecule setup using ansible-galaxy
ansible-galaxy init --init-path custom/ apache-molecule

# Navigate into the new role
cd custom/apache-molecule

# Initialize Molecule in the role with Docker driver
molecule init scenario default --driver-name docker
```

**Command explanations:**
- `ansible-galaxy init`: Creates standard Ansible role structure
- `--init-path custom/`: Creates role in `custom/` subdirectory
- `molecule init scenario`: Adds Molecule testing to existing role
- `--driver-name docker`: Configures Docker as the test platform

**Generated structure:**
```
apache-molecule/
├── defaults/           # Default variables
│   └── main.yml
├── handlers/           # Handler tasks
│   └── main.yml
├── meta/              # Role metadata and dependencies
│   └── main.yml
├── molecule/          # ⭐ Molecule testing framework
│   └── default/       # Default test scenario
│       ├── converge.yml    # Playbook to apply role
│       ├── molecule.yml    # Molecule configuration
│       └── verify.yml      # Verification tests
├── tasks/             # Main role tasks
│   └── main.yml
├── templates/         # Jinja2 templates
├── tests/             # Legacy test inventory
│   ├── inventory
│   └── test.yml
└── vars/              # Role variables
    └── main.yml
```

**Key files explained:**
- **molecule.yml**: Defines test platforms, drivers, and configuration
- **converge.yml**: The playbook that applies your role during testing
- **verify.yml**: Tests to verify role worked correctly

**Expected output:**
```
- Role apache-molecule was created successfully
--> Initializing new scenario default...
Initialized scenario in /home/user/ansible_training/day5/roles/custom/apache-molecule/molecule/default successfully.
```

**Verify the structure:**
```bash
# View the directory structure
tree -L 3 apache-molecule/

# Or if tree not available
ls -R apache-molecule/
```

### 🔧 Part B: Configure Molecule

#### Step 3: Configure molecule.yml

**What this does**: Configures how Molecule will test your role - which containers to use, how to run tests, and what to verify.

**Navigate and edit:**
```bash
# View current molecule config
cat molecule/default/molecule.yml

# Edit with your preferred editor
nano molecule/default/molecule.yml
# OR
vi molecule/default/molecule.yml
```

**Replace the contents with:**
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

provisioner:
  name: ansible
  config_options:
    defaults:
      callbacks_enabled: profile_tasks, timer
      stdout_callback: yaml
  lint:
    name: ansible-lint

verifier:
  name: ansible
```

**Configuration explained:**

1. **dependency**: 
   - `name: galaxy` - Downloads role dependencies from Ansible Galaxy before testing

2. **driver**: 
   - `name: docker` - Uses Docker containers for testing (fast, isolated)

3. **platforms**: 
   - `name: ubuntu-focal` - Name of test instance
   - `image: geerlingguy/docker-ubuntu2004-ansible:latest` - Pre-built Docker image with systemd support
   - `pre_build_image: true` - Use existing image (don't build from Dockerfile)
   - `privileged: true` - Required for systemd to work in containers
   - `volumes` - Mounts cgroup filesystem for systemd
   - `command` - Starts systemd as init system

4. **provisioner**: 
   - `name: ansible` - Use Ansible as the provisioner
   - `callbacks_enabled` - Shows timing and profiling information
   - `lint: ansible-lint` - Runs ansible-lint before testing

5. **verifier**: 
   - `name: ansible` - Use Ansible playbooks for verification tests

**Save the file** (Ctrl+O, Enter, Ctrl+X in nano; :wq in vi)

#### Step 4: Create the Role Tasks

**What this does**: Defines the actual work the role will perform - installing and configuring Apache web server.

**Edit the main tasks file:**
```bash
nano tasks/main.yml
```

**Replace the contents with:**
```yaml
---
# Apache installation and configuration

- name: Update apt cache
  apt:
    update_cache: yes
    cache_valid_time: 3600
  when: ansible_os_family == "Debian"

- name: Install Apache
  package:
    name: "{{ apache_package }}"
    state: present

- name: Ensure Apache is running
  service:
    name: "{{ apache_service }}"
    state: started
    enabled: yes

- name: Deploy custom index page
  template:
    src: index.html.j2
    dest: /var/www/html/index.html
    owner: www-data
    group: www-data
    mode: '0644'
  notify: restart apache
```

**Tasks explained:**

1. **Update apt cache**: Only runs on Debian-based systems, updates package cache
2. **Install Apache**: Uses `package` module with variable `{{ apache_package }}`
3. **Ensure Apache is running**: Starts service and enables on boot
4. **Deploy custom index page**: Uses Jinja2 template, triggers handler on change

**Save the file** (Ctrl+O, Enter, Ctrl+X)

#### Step 5: Define Default Variables

**Edit defaults:**
```bash
nano defaults/main.yml
```

**Add:**
```yaml
---
apache_package: apache2
apache_service: apache2
apache_port: 80
apache_welcome_message: "Apache configured by Ansible with Molecule testing"
```

**Save the file**

#### Step 6: Create the Template

**Create template file:**
```bash
nano templates/index.html.j2
```

**Add this HTML:**
```html
<!DOCTYPE html>
<html>
<head>
    <title>Apache Test</title>
</head>
<body>
    <h1>{{ apache_welcome_message }}</h1>
    <p>Server: {{ ansible_hostname }}</p>
</body>
</html>
```

**Template explained:**
- `{{ apache_welcome_message }}`: Variable from defaults/main.yml
- `{{ ansible_hostname }}`: Ansible fact with hostname

**Save the file**

#### Step 7: Create Handler

**Edit handlers:**
```bash
nano handlers/main.yml
```

**Add:**
```yaml
---
- name: restart apache
  service:
    name: "{{ apache_service }}"
    state: restarted
```

**Handler explained:**
- Triggered by `notify: restart apache` in tasks
- Only runs if a task with notify actually changes something
- Restarts Apache service

**Save the file**

#### Step 8: Create Molecule Converge Playbook

**What this does**: Defines how Molecule will apply your role during testing.

**Edit the converge playbook:**
```bash
nano molecule/default/converge.yml
```

**Replace the contents with:**
```yaml
---
- name: Converge
  hosts: all
  become: true
  
  tasks:
    - name: "Include apache-molecule role"
      include_role:
        name: apache-molecule
```

**Converge playbook explained:**
- `hosts: all`: Run on all test instances defined in molecule.yml
- `become: true`: Use sudo/root privileges
- `include_role`: Apply the apache-molecule role we're testing

**Save the file**

#### Step 9: Create Molecule Verify Tests

**What this does**: Defines automated tests to verify your role worked correctly.

**Edit the verify playbook:**
```bash
nano molecule/default/verify.yml
```

**Replace the contents with:**
```yaml
---
- name: Verify
  hosts: all
  gather_facts: true
  
  tasks:
    - name: Check Apache package is installed
      package:
        name: apache2
        state: present
      check_mode: yes
      register: pkg_check
      failed_when: pkg_check.changed

    - name: Check Apache service is running
      service:
        name: apache2
        state: started
        enabled: yes
      check_mode: yes
      register: svc_check
      failed_when: svc_check.changed

    - name: Test Apache is responding
      uri:
        url: http://localhost
        status_code: 200
        return_content: yes
      register: apache_response
      failed_when: apache_response.status != 200

    - name: Verify custom content
      assert:
        that:
          - "'Ansible with Molecule' in apache_response.content"
        fail_msg: "Custom content not found in Apache response"
        success_msg: "Apache is serving custom content correctly"

    - name: Check Apache configuration file exists
      stat:
        path: /etc/apache2/apache2.conf
      register: apache_conf
      failed_when: not apache_conf.stat.exists
```

**Verification tests explained:**

1. **Check Apache package is installed**:
   - Uses `check_mode: yes` (dry run)
   - `failed_when: pkg_check.changed` - Fails if package would be installed (means it's not there)

2. **Check Apache service is running**:
   - Verifies service is running and enabled
   - Same logic: should already be configured, so nothing should change

3. **Test Apache is responding**:
   - Makes HTTP request to localhost
   - Expects 200 OK status
   - Captures response content for further testing

4. **Verify custom content**:
   - Uses `assert` module
   - Checks if our custom text is in the page
   - Provides helpful success/fail messages

5. **Check Apache configuration file exists**:
   - Uses `stat` module to check file
   - Fails if config file doesn't exist

**Save the file**

### 🔧 Part C: Run Molecule Tests

#### Step 10: Execute Molecule Test Cycle

**What this does**: Runs the complete test lifecycle - creating containers, applying role, verifying results, and cleanup.

**From the role directory, run:**
```bash
# Make sure you're in the role directory
cd ~/ansible_training/day5/roles/custom/apache-molecule

# Run full test sequence (this takes 2-5 minutes)
molecule test
```

**Molecule test sequence:**
```
molecule test runs:
┌──────────────────────────────────────┐
│ 1. dependency  → Install role deps   │
│ 2. lint        → YAML/Ansible lint   │
│ 3. cleanup     → Remove old instances│
│ 4. destroy     → Ensure clean state  │
│ 5. syntax      → Check playbook syntax│
│ 6. create      → Spin up containers  │
│ 7. prepare     → Prep test env      │
│ 8. converge    → Run the role        │
│ 9. idempotence → Run again (no changes)│
│ 10. side_effect→ Optional tasks      │
│ 11. verify     → Run tests           │
│ 12. cleanup    → Clean up            │
│ 13. destroy    → Remove containers   │
└──────────────────────────────────────┘
```

**Expected output (abbreviated):**
```
INFO     default scenario test matrix: dependency, lint, cleanup, destroy, syntax, create, prepare, converge, idempotence, side_effect, verify, cleanup, destroy
INFO     Performing prerun...
INFO     Running default > dependency
INFO     Running default > lint
INFO     Running default > cleanup
INFO     Running default > destroy
INFO     Running default > syntax
INFO     Running default > create
INFO     Running default > prepare
INFO     Running default > converge
PLAY [Converge] ************************************************************
...
PLAY RECAP *****************************************************************
ubuntu-focal               : ok=5    changed=4    unreachable=0    failed=0

INFO     Running default > idempotence
...
PLAY RECAP *****************************************************************
ubuntu-focal               : ok=5    changed=0    unreachable=0    failed=0

INFO     Running default > verify
PLAY [Verify] **************************************************************
...
PLAY RECAP *****************************************************************
ubuntu-focal               : ok=6    changed=0    unreachable=0    failed=0

INFO     Verifier completed successfully.
```

**Success indicators:**
- ✅ All steps complete without errors
- ✅ Idempotence check shows `changed=0` (no changes on second run)
- ✅ All verify tasks pass
- ✅ "Verifier completed successfully" message appears

**Run individual test steps:**

```bash
# 1. Create test infrastructure (Docker container)
molecule create
# Expected: Container "ubuntu-focal" created

# 2. Apply the role (converge)
molecule converge
# Expected: Apache installed and configured

# 3. Test idempotency (should show no changes)
molecule idempotence
# Expected: changed=0 for all tasks

# 4. Run verification tests
molecule verify
# Expected: All assertions pass

# 5. Login to test container (for debugging)
molecule login
# Opens shell in container, type 'exit' to leave

# 6. Destroy test infrastructure
molecule destroy
# Expected: Container removed
```

#### Step 11: Debug Failing Tests

**If tests fail, use these debugging commands:**

```bash
# Run with debug output
molecule --debug test

# Keep container running after test (don't destroy)
molecule test --destroy never

# Then login to inspect
molecule login

# Inside container, check Apache manually:
systemctl status apache2
curl http://localhost
cat /var/www/html/index.html
ls -la /etc/apache2/

# Exit container
exit

# View Molecule logs
ls -la molecule/default/
cat molecule/default/*.log  # If log files exist

# Clean up when done debugging
molecule destroy
```

**Common issues and fixes:**

1. **Docker permission denied**
   ```bash
   sudo usermod -aG docker $USER
   # Logout and login again
   ```

2. **Lint failures**
   ```bash
   # Run lint separately to see details
   ansible-lint tasks/main.yml
   yamllint molecule/
   ```

3. **Idempotence failure** (tasks show changed=1 on second run)
   - Check tasks for non-idempotent operations
   - Ensure `state: present` not `state: latest`
   - Review handler triggers

4. **Verify failures**
   ```bash
   # Test manually in container
   molecule create
   molecule converge
   molecule login
   # Run verification commands manually inside container
   ```

### 🔧 Part D: Test on OpenStack Instance (Integration Testing)

**Why this step?**: Docker tests are great for development, but testing on real infrastructure ensures your role works in production-like environments.

#### Step 12: Prepare OpenStack Instance

**Verify you have an OpenStack instance running:**
```bash
# List your instances
openstack server list

# If you don't have one, see OPENSTACK-TESTING-GUIDE.md
# Or create a quick test instance:
openstack server create \
  --flavor m1.small \
  --image Ubuntu-20.04 \
  --key-name ansible-key \
  --security-group default \
  --security-group web-server \
  apache-molecule-test
```

**Ensure security groups allow required ports:**
```bash
# SSH (should already exist)
openstack security group rule create --protocol tcp --dst-port 22 default

# HTTP for Apache
openstack security group rule create --protocol tcp --dst-port 80 web-server

# Or create new security group
openstack security group create molecule-test
openstack security group rule create --protocol tcp --dst-port 22 molecule-test
openstack security group rule create --protocol tcp --dst-port 80 molecule-test
```

**Get floating IP and add to instance:**
```bash
# Create floating IP
openstack floating ip create public

# Associate with instance
openstack server add floating ip apache-molecule-test <FLOATING_IP>
```

#### Step 13: Create Inventory for OpenStack Testing

**Create inventory file:**
```bash
cd ~/ansible_training/day5/intermediate-labs
nano inventory-openstack.ini
```

**Add:**
```ini
[webservers]
apache-test ansible_host=<FLOATING_IP> ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/ansible-key

[webservers:vars]
ansible_python_interpreter=/usr/bin/python3
```

**Replace `<FLOATING_IP>` with your actual floating IP**

**Save the file**

#### Step 14: Test Connectivity

**Test SSH connection:**
```bash
# Test SSH directly
ssh -i ~/.ssh/ansible-key ubuntu@<FLOATING_IP>
exit

# Test Ansible ping
ansible webservers -i inventory-openstack.ini -m ping
```

**Expected output:**
```
apache-test | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

**Troubleshooting:**
- **Connection timeout**: Check security groups allow SSH port 22
- **Permission denied**: Verify SSH key permissions (`chmod 600 ~/.ssh/ansible-key`)
- **Host key verification**: Add `-o StrictHostKeyChecking=no` for first connection

#### Step 15: Create Playbook for OpenStack Testing

**Create test playbook:**
```bash
nano test-apache-openstack.yml
```

**Add:**
```yaml
---
- name: Test apache-molecule role on OpenStack
  hosts: webservers
  become: yes
  
  roles:
    - role: ../../roles/custom/apache-molecule
```

**Playbook explained:**
- `hosts: webservers`: Targets our OpenStack instance from inventory
- `become: yes`: Uses sudo for installation tasks
- `role: ../../roles/custom/apache-molecule`: Path to our role

**Save the file**

#### Step 16: Deploy to OpenStack

**Run the playbook:**
```bash
# Syntax check first
ansible-playbook test-apache-openstack.yml -i inventory-openstack.ini --syntax-check

# Dry run to see what would change
ansible-playbook test-apache-openstack.yml -i inventory-openstack.ini --check

# Deploy for real
ansible-playbook test-apache-openstack.yml -i inventory-openstack.ini -v
```

**Expected output:**
```
PLAY [Test apache-molecule role on OpenStack] ******************************

TASK [Gathering Facts] *****************************************************
ok: [apache-test]

TASK [apache-molecule : Update apt cache] **********************************
changed: [apache-test]

TASK [apache-molecule : Install Apache] ************************************
changed: [apache-test]

TASK [apache-molecule : Ensure Apache is running] **************************
changed: [apache-test]

TASK [apache-molecule : Deploy custom index page] **************************
changed: [apache-test]

RUNNING HANDLER [apache-molecule : restart apache] *************************
changed: [apache-test]

PLAY RECAP *****************************************************************
apache-test                : ok=6    changed=5    unreachable=0    failed=0
```

**Success indicators:**
- ✅ All tasks complete successfully (ok= count)
- ✅ No failed tasks (failed=0)
- ✅ Handler executed (restart apache)

#### Step 17: Verify OpenStack Deployment

**Test from your local machine:**
```bash
# Test HTTP with curl
curl http://<FLOATING_IP>

# Expected output:
# <h1>Apache configured by Ansible with Molecule testing</h1>
# <p>Server: apache-molecule-test</p>

# Test with browser (copy/paste this URL)
echo "Open in browser: http://<FLOATING_IP>"

# Check headers
curl -I http://<FLOATING_IP>

# Expected:
# HTTP/1.1 200 OK
# Server: Apache/2.4.xx (Ubuntu)
```

**SSH to instance for detailed verification:**
```bash
ssh -i ~/.ssh/ansible-key ubuntu@<FLOATING_IP>

# Check Apache status
sudo systemctl status apache2

# Check listening ports
sudo ss -tlnp | grep apache

# View the deployed page
cat /var/www/html/index.html

# Check Apache access log
sudo tail -20 /var/log/apache2/access.log

# Exit when done
exit
```

#### Step 18: Test Idempotency on OpenStack

**Run playbook again (should show no changes):**
```bash
ansible-playbook test-apache-openstack.yml -i inventory-openstack.ini -v
```

**Expected output:**
```
PLAY RECAP *****************************************************************
apache-test                : ok=6    changed=0    unreachable=0    failed=0
```

**✅ Success**: `changed=0` means role is idempotent

#### Step 19: Compare Docker vs OpenStack Testing

**You've now tested in both environments:**

| Aspect | Docker (Molecule) | OpenStack |
|--------|------------------|-----------|
| **Speed** | ⚡ Fast (seconds) | 🐢 Slower (minutes) |
| **Cost** | 💰 Free | 💰 Uses cloud resources |
| **Isolation** | ✅ Perfect | ⚠️ Need cleanup |
| **Realism** | ⚠️ Simulated | ✅ Real infrastructure |
| **CI/CD** | ✅ Ideal | ⚠️ Requires setup |
| **Use Case** | Development, unit tests | Integration, staging tests |

**Best Practice Workflow:**
1. **Develop**: Use Molecule/Docker for rapid iteration
2. **Test**: Run `molecule test` after each change
3. **Integrate**: Deploy to OpenStack instance before merging
4. **Verify**: Test on real infrastructure with production-like config
5. **CI/CD**: Molecule in CI, OpenStack for staging

### ✅ Expected Results (Complete Lab 5)

1. ✅ All Molecule test stages pass
2. ✅ Apache installed and running in Docker container
3. ✅ Custom content served
4. ✅ Idempotence test passes (no changes on second run)
5. ✅ All verification tests pass
6. ✅ Successfully deployed to OpenStack instance
7. ✅ Role works identically on Docker and OpenStack

### 🎓 Learning Points

- ✅ Molecule installation and setup
- ✅ Docker-based testing for rapid development
- ✅ Test scenarios and verification playbooks
- ✅ Idempotency testing importance
- ✅ Debugging test failures with molecule login
- ✅ Integration testing on OpenStack instances
- ✅ Comparing development vs production environments
- ✅ Best practices: Docker for dev, OpenStack for integration

---

## Lab 6: Multi-Platform Testing with Molecule

### 🎯 Objective
Test your role across multiple operating systems using Molecule to ensure cross-platform compatibility.

### 📋 Prerequisites
- ✅ Completed Lab 5 (Molecule basics)
- ✅ Docker running
- ✅ Multiple container images available

### ⏱️ Estimated Time
60 minutes

### 🧪 What You'll Learn
- Testing across multiple OS distributions
- OS-specific variable management
- Platform compatibility verification
- Matrix testing strategies

### 🔧 Steps

#### Step 1: Configure Multiple Platforms

**What this does**: Configures Molecule to test your role on Ubuntu 20.04, Ubuntu 22.04, and Debian 11 simultaneously.

**Create or use existing role:**
```bash
cd ~/ansible_training/day5/roles/custom/apache-molecule

# Backup existing molecule config
cp molecule/default/molecule.yml molecule/default/molecule.yml.backup

# Edit molecule config
nano molecule/default/molecule.yml
```

**Replace with multi-platform configuration:**

```yaml
---
dependency:
  name: galaxy

driver:
  name: docker

platforms:
  - name: ubuntu-20
    image: geerlingguy/docker-ubuntu2004-ansible:latest
    pre_build_image: true
    privileged: true
    volumes:
      - /sys/fs/cgroup:/sys/fs/cgroup:ro
    command: /lib/systemd/systemd
    groups:
      - ubuntu_family
  
  - name: ubuntu-22
    image: geerlingguy/docker-ubuntu2204-ansible:latest
    pre_build_image: true
    privileged: true
    volumes:
      - /sys/fs/cgroup:/sys/fs/cgroup:ro
    command: /lib/systemd/systemd
    groups:
      - ubuntu_family
  
  - name: debian-11
    image: geerlingguy/docker-debian11-ansible:latest
    pre_build_image: true
    privileged: true
    volumes:
      - /sys/fs/cgroup:/sys/fs/cgroup:ro
    command: /lib/systemd/systemd
    groups:
      - debian_family

provisioner:
  name: ansible
  config_options:
    defaults:
      callbacks_enabled: profile_tasks, timer
  inventory:
    host_vars:
      ubuntu-20:
        apache_welcome_message: "Apache on Ubuntu 20.04"
      ubuntu-22:
        apache_welcome_message: "Apache on Ubuntu 22.04"
      debian-11:
        apache_welcome_message: "Apache on Debian 11"

verifier:
  name: ansible
```

#### Step 2: Update Role for Cross-Platform Support

Edit `vars/main.yml` - create OS-specific variables:

```yaml
# vars/Debian.yml
---
apache_package: apache2
apache_service: apache2
apache_config_path: /etc/apache2/apache2.conf
apache_sites_available: /etc/apache2/sites-available
apache_sites_enabled: /etc/apache2/sites-enabled

# vars/RedHat.yml  
---
apache_package: httpd
apache_service: httpd
apache_config_path: /etc/httpd/conf/httpd.conf
apache_conf_d: /etc/httpd/conf.d
```

Update `tasks/main.yml`:

```yaml
---
- name: Include OS-specific variables
  include_vars: "{{ ansible_os_family }}.yml"

- name: Update package cache (Debian)
  apt:
    update_cache: yes
    cache_valid_time: 3600
  when: ansible_os_family == "Debian"

- name: Install Apache
  package:
    name: "{{ apache_package }}"
    state: present

- name: Ensure Apache is running
  service:
    name: "{{ apache_service }}"
    state: started
    enabled: yes

- name: Deploy custom index page
  template:
    src: index.html.j2
    dest: /var/www/html/index.html
    owner: "{{ 'www-data' if ansible_os_family == 'Debian' else 'apache' }}"
    mode: '0644'
  notify: restart apache
```

#### Step 3: Create Platform-Specific Verification

Edit `molecule/default/verify.yml`:

```yaml
---
- name: Verify
  hosts: all
  gather_facts: true
  
  tasks:
    - name: Set facts based on OS
      set_fact:
        expected_package: "{{ 'apache2' if ansible_os_family == 'Debian' else 'httpd' }}"
        expected_service: "{{ 'apache2' if ansible_os_family == 'Debian' else 'httpd' }}"

    - name: Display test information
      debug:
        msg:
          - "Testing on: {{ ansible_distribution }} {{ ansible_distribution_version }}"
          - "Expected package: {{ expected_package }}"
          - "Expected service: {{ expected_service }}"

    - name: Check Apache package is installed
      package:
        name: "{{ expected_package }}"
        state: present
      check_mode: yes
      register: pkg_check
      failed_when: pkg_check.changed

    - name: Check Apache service is running
      service:
        name: "{{ expected_service }}"
        state: started
      check_mode: yes
      register: svc_check
      failed_when: svc_check.changed

    - name: Test Apache response
      uri:
        url: http://localhost
        status_code: 200
        return_content: yes
      register: response

    - name: Verify platform-specific content
      assert:
        that:
          - "ansible_distribution in response.content"
        fail_msg: "Platform-specific content not found"
```

#### Step 4: Run Multi-Platform Tests

```bash
# Test all platforms
molecule test

# Test specific platform
molecule test --platform-name ubuntu-22

# Create all platforms
molecule create

# Converge on all platforms
molecule converge

# Run verify on all platforms
molecule verify

# Keep instances running
molecule converge --destroy=never

# Login to specific instance
molecule login --host ubuntu-22
```

#### Step 5: Matrix Testing with GitHub Actions

Create `.github/workflows/molecule.yml`:

```yaml
name: Molecule CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  molecule:
    runs-on: ubuntu-latest
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
          python-version: '3.9'

      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install molecule[docker] ansible-lint yamllint

      - name: Run Molecule tests
        run: molecule test
        env:
          MOLECULE_DISTRO: ${{ matrix.distro }}
```

### ✅ Expected Results

1. ✅ Role tested on multiple platforms
2. ✅ Platform-specific configurations working
3. ✅ All tests passing on all platforms
4. ✅ CI/CD pipeline configured

### 🎓 Learning Points

- ✅ Multi-platform testing
- ✅ OS-specific variables and tasks
- ✅ Matrix testing strategies
- ✅ CI/CD integration
- ✅ Platform-specific verification

---

## Lab 7: Publishing Roles to Ansible Galaxy

### 🎯 Objective
Prepare and publish your role to Ansible Galaxy.

### 🔧 Part A: Prepare Role for Publication

#### Step 1: Complete meta/main.yml

Edit `meta/main.yml`:

```yaml
---
galaxy_info:
  role_name: apache_molecule
  author: Your Name
  description: Production-ready Apache web server role with comprehensive testing
  company: Your Company
  
  license: MIT
  
  min_ansible_version: "2.9"
  
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
    - web
    - apache
    - webserver
    - http
    - production
    - molecule
    - tested

dependencies: []
```

#### Step 2: Create Comprehensive README

Create/edit `README.md`:

```markdown
# Ansible Role: Apache Molecule

[![CI](https://github.com/yourusername/ansible-role-apache-molecule/workflows/Molecule%20CI/badge.svg)](https://github.com/yourusername/ansible-role-apache-molecule/actions)
[![Ansible Galaxy](https://img.shields.io/badge/galaxy-yourusername.apache__molecule-blue.svg)](https://galaxy.ansible.com/yourusername/apache_molecule)
[![License](https://img.shields.io/badge/license-MIT-brightgreen.svg)](LICENSE)

Production-ready Apache web server role tested with Molecule across multiple platforms.

## Features

- ✅ Multi-platform support (Ubuntu 20.04/22.04, Debian 11)
- ✅ Fully tested with Molecule
- ✅ Idempotent operations
- ✅ Customizable configuration
- ✅ CI/CD ready

## Requirements

- Ansible >= 2.9
- Supported platforms:
  - Ubuntu 20.04 (Focal)
  - Ubuntu 22.04 (Jammy)
  - Debian 11 (Bullseye)

## Role Variables

Available variables with default values (see `defaults/main.yml`):

```yaml
# Apache package and service names (auto-detected)
apache_package: apache2
apache_service: apache2

# Apache configuration
apache_port: 80
apache_welcome_message: "Welcome to Apache"

# Enable/disable features
apache_enable_mod_rewrite: true
apache_enable_mod_ssl: false
```

## Dependencies

None.

## Example Playbook

### Basic Usage

```yaml
- hosts: webservers
  become: yes
  roles:
    - role: yourusername.apache_molecule
```

### With Custom Variables

```yaml
- hosts: webservers
  become: yes
  roles:
    - role: yourusername.apache_molecule
      vars:
        apache_port: 8080
        apache_welcome_message: "My Custom Apache Server"
```

### With Multiple Sites

```yaml
- hosts: webservers
  become: yes
  roles:
    - role: yourusername.apache_molecule
      vars:
        apache_sites:
          - name: example.com
            port: 80
            docroot: /var/www/example.com
          - name: test.com
            port: 8080
            docroot: /var/www/test.com
```

## Testing

This role includes comprehensive Molecule tests:

```bash
# Install test dependencies
pip install molecule[docker] ansible-lint yamllint

# Run all tests
molecule test

# Test specific platform
molecule test --platform-name ubuntu-22

# Keep test environment
molecule converge --destroy=never
```

### Test Matrix

| Platform | Status |
|----------|--------|
| Ubuntu 20.04 | ✅ Passing |
| Ubuntu 22.04 | ✅ Passing |
| Debian 11 | ✅ Passing |

## CI/CD

This role is automatically tested using GitHub Actions on every push and pull request.

## License

MIT

## Author Information

Created by [Your Name](https://github.com/yourusername)

For issues and contributions, visit: https://github.com/yourusername/ansible-role-apache-molecule

## Changelog

### Version 1.0.0 (2024-01-15)
- Initial release
- Multi-platform support
- Molecule testing
- CI/CD integration
```

#### Step 3: Add LICENSE File

Create `LICENSE`:

```
MIT License

Copyright (c) 2024 Your Name

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

#### Step 4: Create .gitignore

Create `.gitignore`:

```
# Molecule
.molecule/
.cache/

# Python
*.pyc
__pycache__/
.pytest_cache/

# Ansible
*.retry

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Testing
.tox/
.coverage
htmlcov/
```

### 🔧 Part B: Push to GitHub

#### Step 5: Initialize Git Repository

```bash
cd ~/ansible_training/day5/roles/custom/apache-molecule/

# Initialize git
git init

# Add all files
git add .

# Create initial commit
git commit -m "Initial commit: Apache role with Molecule testing"

# Create main branch
git branch -M main
```

#### Step 6: Create GitHub Repository

```bash
# Using GitHub CLI (if installed)
gh repo create ansible-role-apache-molecule --public --source=. --remote=origin

# Or manually:
# 1. Go to https://github.com/new
# 2. Create repository: ansible-role-apache-molecule
# 3. Don't initialize with README (we have one)
# 4. Copy the remote URL
```

#### Step 7: Push to GitHub

```bash
# Add remote (if not using gh CLI)
git remote add origin https://github.com/yourusername/ansible-role-apache-molecule.git

# Push to GitHub
git push -u origin main

# Create and push version tag
git tag 1.0.0
git push origin 1.0.0
```

### 🔧 Part C: Publish to Ansible Galaxy

#### Step 8: Connect GitHub to Galaxy

1. Go to https://galaxy.ansible.com/
2. Click "Sign In" → Use GitHub account
3. Authorize Ansible Galaxy to access your GitHub
4. You'll be redirected to your Galaxy profile

#### Step 9: Import Role to Galaxy

**Method 1: Web Interface**

1. Go to "My Content" → "Repositories"
2. Click "Add Content" → "Import Role from GitHub"
3. Select your repository: `ansible-role-apache-molecule`
4. Click "Import"
5. Wait for import to complete

**Method 2: Command Line**

```bash
# Login to Galaxy (will open browser for GitHub auth)
ansible-galaxy login

# Import the role
ansible-galaxy import yourusername ansible-role-apache-molecule

# Check import status
ansible-galaxy info yourusername.apache_molecule
```

#### Step 10: Configure Auto-Import

Enable automatic imports on new tags:

1. In Galaxy, go to your role
2. Click "Settings"
3. Enable "Travis CI" or "GitHub Actions"
4. Galaxy will set up webhook automatically

Now, whenever you push a new tag:
```bash
git tag 1.0.1
git push origin 1.0.1
# Galaxy automatically imports the new version
```

#### Step 11: Test Installing Your Role

```bash
# Install from Galaxy
ansible-galaxy install yourusername.apache_molecule

# Install specific version
ansible-galaxy install yourusername.apache_molecule,1.0.0

# List installed roles
ansible-galaxy list

# Get role info
ansible-galaxy info yourusername.apache_molecule
```

### ✅ Expected Results

1. ✅ Role published to Galaxy
2. ✅ Accessible via `ansible-galaxy install`
3. ✅ Automatic updates on new tags
4. ✅ Searchable on Galaxy website
5. ✅ CI/CD badge showing in README

### 🎓 Learning Points

- ✅ Role publication workflow
- ✅ Galaxy namespace and naming
- ✅ GitHub integration
- ✅ Versioning and tagging
- ✅ Auto-import configuration

---

## Lab 8: Role Updates and Versioning

### 🎯 Objective
Learn semantic versioning and how to update published roles.

### 🔧 Steps

#### Step 1: Create CHANGELOG.md

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2024-01-15

### Added
- Initial release
- Apache installation and configuration
- Multi-platform support (Ubuntu 20.04/22.04, Debian 11)
- Molecule testing framework
- GitHub Actions CI/CD
- Comprehensive documentation

[Unreleased]: https://github.com/yourusername/ansible-role-apache-molecule/compare/1.0.0...HEAD
[1.0.0]: https://github.com/yourusername/ansible-role-apache-molecule/releases/tag/1.0.0
```

#### Step 2: Make Changes (Bug Fix Release - Patch)

```bash
# Fix a bug in the role
vim tasks/main.yml

# Commit the fix
git add tasks/main.yml
git commit -m "Fix: Correct Apache service handler notification"

# Update CHANGELOG
vim CHANGELOG.md
# Add entry under [Unreleased] or create [1.0.1]

# Tag patch release
git tag 1.0.1
git push origin main
git push origin 1.0.1
```

**CHANGELOG for 1.0.1:**
```markdown
## [1.0.1] - 2024-01-20

### Fixed
- Corrected Apache service handler notification
- Fixed template permissions on Debian systems
```

#### Step 3: Add New Feature (Minor Release)

```bash
# Add new feature - SSL support
vim defaults/main.yml  # Add SSL variables
vim tasks/ssl.yml      # Create SSL tasks
vim tasks/main.yml     # Include SSL tasks

# Commit the feature
git add .
git commit -m "Feature: Add SSL/TLS configuration support"

# Tag minor release
git tag 1.1.0
git push origin main
git push origin 1.1.0
```

**CHANGELOG for 1.1.0:**
```markdown
## [1.1.0] - 2024-02-01

### Added
- SSL/TLS configuration support
- New variables for certificate paths
- Automatic redirect from HTTP to HTTPS
- SSL module verification

### Changed
- Updated README with SSL examples
- Enhanced Molecule tests for SSL scenarios
```

#### Step 4: Breaking Change (Major Release)

```bash
# Make breaking changes - rename variables
# Old: apache_document_root
# New: apache_docroot

vim defaults/main.yml
vim tasks/main.yml
vim README.md

# Add deprecation warning for one version
vim tasks/main.yml
```

```yaml
# Add deprecation handling
- name: Check for deprecated variables
  fail:
    msg: |
      BREAKING CHANGE: Variable 'apache_document_root' has been renamed to 'apache_docroot'.
      Please update your playbooks. This role requires version 2.0.0+
  when:
    - apache_document_root is defined
    - apache_docroot is not defined
```

```bash
# Commit breaking change
git add .
git commit -m "BREAKING: Rename apache_document_root to apache_docroot"

# Tag major release
git tag 2.0.0
git push origin main
git push origin 2.0.0
```

**CHANGELOG for 2.0.0:**
```markdown
## [2.0.0] - 2024-03-01

### Changed
- **BREAKING**: Renamed `apache_document_root` to `apache_docroot`
- **BREAKING**: Changed default Apache port from 80 to 8080
- Restructured variable naming for consistency

### Migration Guide

To upgrade from 1.x to 2.0:

1. Rename variables in your playbooks:
   ```yaml
   # Old (1.x)
   apache_document_root: /var/www/html
   
   # New (2.0)
   apache_docroot: /var/www/html
   ```

2. Check port configuration:
   ```yaml
   # Explicitly set if you want port 80
   apache_port: 80
   ```

### Added
- Support for Ubuntu 24.04
- New module: mod_security integration
```

#### Step 5: Use Version Constraints in requirements.yml

```yaml
---
# Install exact version
- name: yourusername.apache_molecule
  version: "1.0.1"

# Install any 1.x version
- name: yourusername.apache_molecule
  version: "~1.0"

# Install 1.0.0 or higher
- name: yourusername.apache_molecule
  version: ">=1.0.0"

# Install 1.x but not 2.x (avoid breaking changes)
- name: yourusername.apache_molecule
  version: ">=1.0.0,<2.0.0"
```

### ✅ Expected Results

1. ✅ Proper semantic versioning
2. ✅ Clear changelog maintenance
3. ✅ Breaking changes documented
4. ✅ Migration guides provided
5. ✅ Galaxy auto-updates with new versions

### 🎓 Learning Points

- ✅ Semantic versioning (MAJOR.MINOR.PATCH)
- ✅ Changelog management
- ✅ Handling breaking changes
- ✅ Version constraints in requirements
- ✅ Migration strategies

---

## Lab 9: Advanced Molecule Scenarios

### 🎯 Objective
Create custom Molecule scenarios for different testing needs.

### 🔧 Steps

#### Step 1: Create Production Scenario

```bash
cd ~/ansible_training/day5/roles/custom/apache-molecule/

# Create production test scenario
molecule init scenario production --driver-name docker
```

Edit `molecule/production/molecule.yml`:

```yaml
---
dependency:
  name: galaxy

driver:
  name: docker

platforms:
  - name: prod-ubuntu-22
    image: geerlingguy/docker-ubuntu2204-ansible:latest
    pre_build_image: true
    privileged: true
    volumes:
      - /sys/fs/cgroup:/sys/fs/cgroup:ro
    command: /lib/systemd/systemd
    published_ports:
      - "0.0.0.0:8080:80/tcp"

provisioner:
  name: ansible
  inventory:
    host_vars:
      prod-ubuntu-22:
        apache_port: 80
        apache_welcome_message: "Production Apache Server"
        apache_enable_mod_ssl: true
        apache_enable_mod_security: true

verifier:
  name: ansible
```

Edit `molecule/production/converge.yml`:

```yaml
---
- name: Converge (Production)
  hosts: all
  become: true
  
  pre_tasks:
    - name: Install production requirements
      apt:
        name:
          - ssl-cert
          - libapache2-mod-security2
        state: present
  
  roles:
    - role: apache-molecule
  
  post_tasks:
    - name: Harden Apache configuration
      lineinfile:
        path: /etc/apache2/conf-enabled/security.conf
        regexp: "^ServerTokens"
        line: "ServerTokens Prod"
      notify: restart apache
```

Edit `molecule/production/verify.yml`:

```yaml
---
- name: Verify (Production)
  hosts: all
  gather_facts: true
  
  tasks:
    - name: Check Apache is listening on port 80
      wait_for:
        port: 80
        timeout: 10

    - name: Test Apache response
      uri:
        url: http://localhost
        status_code: 200
      register: response

    - name: Verify security headers
      uri:
        url: http://localhost
        return_content: yes
      register: headers

    - name: Check for production hardening
      assert:
        that:
          - "'ServerTokens Prod' in lookup('file', '/etc/apache2/conf-enabled/security.conf')"
        fail_msg: "Production hardening not applied"

    - name: Verify SSL module is enabled
      stat:
        path: /etc/apache2/mods-enabled/ssl.conf
      register: ssl_mod
      failed_when: not ssl_mod.stat.exists
```

#### Step 2: Create Development Scenario

```bash
molecule init scenario development --driver-name docker
```

Edit `molecule/development/molecule.yml`:

```yaml
---
platforms:
  - name: dev-ubuntu
    image: ubuntu:22.04
    pre_build_image: false
    dockerfile: ../resources/Dockerfile.j2
    command: /lib/systemd/systemd
    published_ports:
      - "0.0.0.0:8081:80/tcp"

provisioner:
  name: ansible
  inventory:
    host_vars:
      dev-ubuntu:
        apache_port: 80
        apache_enable_debug: true
        apache_log_level: debug
```

#### Step 3: Create Custom Dockerfile for Tests

Create `molecule/resources/Dockerfile.j2`:

```dockerfile
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y \
        python3 \
        python3-apt \
        systemd \
        systemd-sysv \
        sudo && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Remove unnecessary systemd services
RUN cd /lib/systemd/system/sysinit.target.wants/ && \
    ls | grep -v systemd-tmpfiles-setup | xargs rm -f $1

RUN rm -f /lib/systemd/system/multi-user.target.wants/* \
    /etc/systemd/system/*.wants/* \
    /lib/systemd/system/local-fs.target.wants/* \
    /lib/systemd/system/sockets.target.wants/*udev* \
    /lib/systemd/system/sockets.target.wants/*initctl* \
    /lib/systemd/system/basic.target.wants/* \
    /lib/systemd/system/anaconda.target.wants/* \
    /lib/systemd/system/plymouth* \
    /lib/systemd/system/systemd-update-utmp*

VOLUME ["/sys/fs/cgroup"]

CMD ["/lib/systemd/systemd"]
```

#### Step 4: Test Different Scenarios

```bash
# Test default scenario
molecule test

# Test production scenario
molecule test -s production

# Test development scenario
molecule test -s development

# Run all scenarios
for scenario in default production development; do
    molecule test -s $scenario
done
```

### ✅ Expected Results

1. ✅ Multiple test scenarios configured
2. ✅ Scenario-specific configurations
3. ✅ Different verification tests per scenario
4. ✅ Custom Docker images for testing

### 🎓 Learning Points

- ✅ Multiple Molecule scenarios
- ✅ Scenario-specific configuration
- ✅ Custom Docker images
- ✅ Environment-specific testing

---

## 📝 Practice Exercises

### Exercise 1: Create and Publish MySQL Role
1. Create MySQL role with Molecule testing
2. Test on Ubuntu and Debian
3. Publish to Galaxy
4. Add version 1.0.0 tag

### Exercise 2: Create Role Collection
1. Create collection structure
2. Include multiple roles
3. Publish to Galaxy
4. Document dependencies

### Exercise 3: CI/CD Pipeline
1. Set up GitHub Actions
2. Test on multiple platforms
3. Auto-publish to Galaxy on tags
4. Add status badges

---

## 🎯 Summary

**What You've Learned:**

✅ Molecule testing framework  
✅ Multi-platform testing  
✅ Publishing to Ansible Galaxy  
✅ GitHub integration  
✅ Semantic versioning  
✅ Changelog management  
✅ Custom test scenarios  
✅ CI/CD integration  

**Next Steps:**
- Proceed to advanced labs
- Create production-ready roles
- Contribute to community roles

---

**🎉 Congratulations! You've mastered intermediate role development!**
