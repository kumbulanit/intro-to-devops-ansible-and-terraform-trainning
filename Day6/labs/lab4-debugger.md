# Lab 4: Interactive Playbook Debugging

## 🎯 Lab Objectives

By completing this lab, you will:

- ✅ Enable and use the Ansible debugger
- ✅ Inspect variables during execution
- ✅ Debug failed tasks interactively
- ✅ Modify task arguments in the debugger
- ✅ Use debugger commands effectively
- ✅ Troubleshoot real-world deployment issues

## ⏱️ Estimated Time

45 minutes

---

## 🔧 Lab Setup

### Prerequisites

- Ansible 2.9+ installed
- SSH access to test servers (or use localhost)
- Text editor (vim, nano, or VS Code)

### Create Lab Directory

```bash
mkdir -p ~/ansible-labs/lab4-debugger
cd ~/ansible-labs/lab4-debugger
```

### Create Inventory File

```bash
cat > inventory.ini << 'EOF'
[local]
localhost ansible_connection=local

[webservers]
web1 ansible_host=localhost ansible_connection=local ansible_port=22

# For OpenStack instances (if available)
# web1 ansible_host=<floating_ip> ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/openstack_key

[dbservers]
db1 ansible_host=localhost ansible_connection=local

[all:vars]
ansible_python_interpreter=/usr/bin/python3
EOF
```

---

## 📝 Exercise 1: Basic Debugger Usage

### Objective

Learn to enable the debugger and use basic commands.

### Step 1: Create a Simple Failing Playbook

```bash
cat > exercise1-basic-debug.yml << 'EOF'
---
- name: Exercise 1 - Basic Debugger
  hosts: local
  debugger: on_failed
  gather_facts: no
  
  vars:
    app_name: "myapp"
    version: "1.0.0"
    install_path: "/opt/myapp"
  
  tasks:
    - name: Display app info
      debug:
        msg: "Installing {{ app_name }} version {{ version }}"
    
    - name: Create directory (will succeed)
      file:
        path: /tmp/test-app
        state: directory
        mode: '0755'
    
    - name: Copy non-existent file (will fail)
      copy:
        src: /nonexistent/file.txt
        dest: /tmp/test-app/file.txt
    
    - name: This won't run (previous task failed)
      debug:
        msg: "Post-installation steps"
EOF
```

### Step 2: Run with Debugger

```bash
ansible-playbook -i inventory.ini exercise1-basic-debug.yml
```

### Step 3: Debug Session Practice

When the debugger activates at the failed task, practice these commands:

**a) Inspect variables:**

```
[localhost] TASK: Copy non-existent file (will fail) (debug)> p app_name
'myapp'

[localhost] TASK: Copy non-existent file (will fail) (debug)> p version
'1.0.0'

[localhost] TASK: Copy non-existent file (will fail) (debug)> p install_path
'/opt/myapp'
```

**b) Check task arguments:**

```
[localhost] TASK: Copy non-existent file (will fail) (debug)> p task.args
{'dest': '/tmp/test-app/file.txt', 'src': '/nonexistent/file.txt'}
```

**c) View the error result:**

```
[localhost] TASK: Copy non-existent file (will fail) (debug)> p result
```

**d) Fix the source path and retry:**

```bash
# First, create a test file
echo "test content" > /tmp/testfile.txt
```

Then in debugger:

```
[localhost] TASK: Copy non-existent file (will fail) (debug)> task.args['src'] = '/tmp/testfile.txt'

[localhost] TASK: Copy non-existent file (will fail) (debug)> p task.args
{'dest': '/tmp/test-app/file.txt', 'src': '/tmp/testfile.txt'}

[localhost] TASK: Copy non-existent file (will fail) (debug)> redo
```

**e) Continue execution:**

```
[localhost] TASK: Copy non-existent file (will fail) (debug)> c
```

### Expected Output

```
PLAY [Exercise 1 - Basic Debugger] *********************************************

TASK [Display app info] ********************************************************
ok: [localhost] => {
    "msg": "Installing myapp version 1.0.0"
}

TASK [Create directory (will succeed)] *****************************************
changed: [localhost]

TASK [Copy non-existent file (will fail)] **************************************
fatal: [localhost]: FAILED! => {"changed": false, "msg": "Could not find file"}

[localhost] TASK: Copy non-existent file (will fail) (debug)> 
# Your debug session here
```

### Validation

```bash
# Check if file was created after fixing
ls -la /tmp/test-app/file.txt
cat /tmp/test-app/file.txt
```

---

## 📝 Exercise 2: Debugging Variable Issues

### Objective

Learn to debug undefined variables and variable interpolation issues.

### Step 1: Create Playbook with Variable Issues

```bash
cat > exercise2-variable-debug.yml << 'EOF'
---
- name: Exercise 2 - Variable Debugging
  hosts: local
  debugger: on_failed
  gather_facts: yes
  
  vars:
    database:
      host: "db.example.com"
      port: 5432
      name: "production_db"
    
    app_config:
      debug_mode: false
      log_level: "INFO"
      max_connections: 100
  
  tasks:
    - name: Display database info
      debug:
        msg: "Database: {{ database.host }}:{{ database.port }}/{{ database.name }}"
    
    - name: Use undefined variable (will fail)
      debug:
        msg: "Username: {{ database.username }}"
    
    - name: Configure application
      template:
        src: config.j2
        dest: /tmp/app-config.yml
EOF
```

### Step 2: Run and Debug

```bash
ansible-playbook -i inventory.ini exercise2-variable-debug.yml
```

### Step 3: Debug Session

**a) Inspect the database variable:**

```
[localhost] TASK: Use undefined variable (will fail) (debug)> p database
{'host': 'db.example.com', 'name': 'production_db', 'port': 5432}

[localhost] TASK: Use undefined variable (will fail) (debug)> p database.keys()
['host', 'port', 'name']
```

**b) Note that 'username' is missing, add it:**

```
[localhost] TASK: Use undefined variable (will fail) (debug)> database['username'] = 'app_user'

[localhost] TASK: Use undefined variable (will fail) (debug)> p database
{'host': 'db.example.com', 'name': 'production_db', 'port': 5432, 'username': 'app_user'}
```

**c) Retry the task:**

```
[localhost] TASK: Use undefined variable (will fail) (debug)> redo
```

**d) Skip the template task (since we don't have the template):**

```
[localhost] TASK: Configure application (debug)> q
```

### Expected Output

```
TASK [Display database info] ***************************************************
ok: [localhost] => {
    "msg": "Database: db.example.com:5432/production_db"
}

TASK [Use undefined variable (will fail)] **************************************
fatal: [localhost]: FAILED! => {"msg": "The task includes an option with an undefined variable. The error was: 'dict object' has no attribute 'username'"}

[localhost] TASK: Use undefined variable (will fail) (debug)> 
```

---

## 📝 Exercise 3: Debugging Complex Deployments

### Objective

Debug a multi-step deployment with realistic failure scenarios.

### Step 1: Create Deployment Playbook

```bash
cat > exercise3-deployment-debug.yml << 'EOF'
---
- name: Exercise 3 - Complex Deployment Debugging
  hosts: local
  become: no
  debugger: on_failed
  
  vars:
    app_name: "webapp"
    app_version: "2.0.0"
    app_port: 8080
    deploy_user: "{{ ansible_user_id }}"
    deploy_path: "/tmp/deployments/{{ app_name }}"
    backup_path: "/tmp/backups"
  
  tasks:
    - name: Ensure deployment directory exists
      file:
        path: "{{ deploy_path }}"
        state: directory
        mode: '0755'
      register: deploy_dir
    
    - name: Ensure backup directory exists
      file:
        path: "{{ backup_path }}"
        state: directory
        mode: '0755'
    
    - name: Check if previous version exists
      stat:
        path: "{{ deploy_path }}/current"
      register: current_version
    
    - name: Backup current version
      command: >
        cp -r {{ deploy_path }}/current
        {{ backup_path }}/backup-{{ ansible_date_time.epoch }}
      when: current_version.stat.exists
      register: backup_result
    
    - name: Download application (simulated - will fail)
      get_url:
        url: "https://releases.example.com/{{ app_name }}-{{ app_version }}.tar.gz"
        dest: "/tmp/{{ app_name }}-{{ app_version }}.tar.gz"
        timeout: 30
      register: download_result
    
    - name: Extract application
      unarchive:
        src: "/tmp/{{ app_name }}-{{ app_version }}.tar.gz"
        dest: "{{ deploy_path }}"
        remote_src: yes
      when: download_result is succeeded
    
    - name: Create symlink to current version
      file:
        src: "{{ deploy_path }}/{{ app_name }}-{{ app_version }}"
        dest: "{{ deploy_path }}/current"
        state: link
    
    - name: Verify deployment
      debug:
        msg: "Successfully deployed {{ app_name }} version {{ app_version }}"
EOF
```

### Step 2: Run and Debug

```bash
ansible-playbook -i inventory.ini exercise3-deployment-debug.yml
```

### Step 3: Debug the Download Failure

**a) Inspect the download task:**

```
[localhost] TASK: Download application (simulated - will fail) (debug)> p task.args
{'dest': '/tmp/webapp-2.0.0.tar.gz',
 'timeout': 30,
 'url': 'https://releases.example.com/webapp-2.0.0.tar.gz'}

[localhost] TASK: Download application (simulated - will fail) (debug)> p app_version
'2.0.0'
```

**b) Simulate fixing by creating a local file:**

```
[localhost] TASK: Download application (simulated - will fail) (debug)> q
```

Exit and create a fake archive:

```bash
# Create fake application for testing
mkdir -p /tmp/webapp-2.0.0
echo "#!/bin/bash" > /tmp/webapp-2.0.0/start.sh
echo "echo 'Starting webapp 2.0.0 on port 8080'" >> /tmp/webapp-2.0.0/start.sh
chmod +x /tmp/webapp-2.0.0/start.sh

# Create tarball
cd /tmp
tar -czf webapp-2.0.0.tar.gz webapp-2.0.0/
```

### Step 4: Modify Playbook to Use Local File

```bash
cat > exercise3-deployment-debug-fixed.yml << 'EOF'
---
- name: Exercise 3 - Complex Deployment (Fixed)
  hosts: local
  become: no
  debugger: on_failed
  
  vars:
    app_name: "webapp"
    app_version: "2.0.0"
    app_port: 8080
    deploy_user: "{{ ansible_user_id }}"
    deploy_path: "/tmp/deployments/{{ app_name }}"
    backup_path: "/tmp/backups"
  
  tasks:
    - name: Ensure deployment directory exists
      file:
        path: "{{ deploy_path }}"
        state: directory
        mode: '0755'
      register: deploy_dir
    
    - name: Ensure backup directory exists
      file:
        path: "{{ backup_path }}"
        state: directory
        mode: '0755'
    
    - name: Check if previous version exists
      stat:
        path: "{{ deploy_path }}/current"
      register: current_version
    
    - name: Backup current version
      command: >
        cp -r {{ deploy_path }}/current
        {{ backup_path }}/backup-{{ ansible_date_time.epoch }}
      when: current_version.stat.exists
      register: backup_result
    
    - name: Copy local application package
      copy:
        src: "/tmp/{{ app_name }}-{{ app_version }}.tar.gz"
        dest: "/tmp/{{ app_name }}-{{ app_version }}.tar.gz"
      register: copy_result
    
    - name: Extract application
      unarchive:
        src: "/tmp/{{ app_name }}-{{ app_version }}.tar.gz"
        dest: "{{ deploy_path }}"
        remote_src: yes
      when: copy_result is succeeded
    
    - name: Create symlink to current version
      file:
        src: "{{ deploy_path }}/{{ app_name }}-{{ app_version }}"
        dest: "{{ deploy_path }}/current"
        state: link
        force: yes
    
    - name: Verify deployment
      stat:
        path: "{{ deploy_path }}/current/start.sh"
      register: verify_result
    
    - name: Display deployment status
      debug:
        msg: "Successfully deployed {{ app_name }} version {{ app_version }}"
      when: verify_result.stat.exists
EOF
```

### Step 5: Run Fixed Version

```bash
ansible-playbook -i inventory.ini exercise3-deployment-debug-fixed.yml
```

### Expected Output

```
PLAY [Exercise 3 - Complex Deployment (Fixed)] *********************************

TASK [Ensure deployment directory exists] **************************************
changed: [localhost]

TASK [Ensure backup directory exists] ******************************************
ok: [localhost]

TASK [Check if previous version exists] ****************************************
ok: [localhost]

TASK [Backup current version] **************************************************
skipping: [localhost]

TASK [Copy local application package] ******************************************
ok: [localhost]

TASK [Extract application] *****************************************************
changed: [localhost]

TASK [Create symlink to current version] ***************************************
changed: [localhost]

TASK [Verify deployment] *******************************************************
ok: [localhost]

TASK [Display deployment status] ***********************************************
ok: [localhost] => {
    "msg": "Successfully deployed webapp version 2.0.0"
}

PLAY RECAP *********************************************************************
localhost : ok=8 changed=3 unreachable=0 failed=0 skipped=1 rescued=0 ignored=0
```

### Validation

```bash
# Check deployment structure
ls -la /tmp/deployments/webapp/
ls -la /tmp/deployments/webapp/current
cat /tmp/deployments/webapp/current/start.sh
```

---

## 📝 Exercise 4: Debugging with Always Mode

### Objective

Use debugger in `always` mode to step through playbook execution.

### Step 1: Create Stepwise Execution Playbook

```bash
cat > exercise4-always-debug.yml << 'EOF'
---
- name: Exercise 4 - Stepwise Debugging
  hosts: local
  debugger: always  # Debug every task
  gather_facts: no
  
  vars:
    config_items:
      - name: "max_connections"
        value: 100
      - name: "timeout"
        value: 30
      - name: "debug_mode"
        value: false
  
  tasks:
    - name: Start configuration
      debug:
        msg: "Starting configuration with {{ config_items | length }} items"
    
    - name: Process configuration items
      debug:
        msg: "Setting {{ item.name }} = {{ item.value }}"
      loop: "{{ config_items }}"
    
    - name: Complete configuration
      debug:
        msg: "Configuration completed successfully"
EOF
```

### Step 2: Run with Always Debugger

```bash
ansible-playbook -i inventory.ini exercise4-always-debug.yml
```

### Step 3: Step Through Execution

**Task 1 - Start configuration:**

```
[localhost] TASK: Start configuration (debug)> p config_items
[{'name': 'max_connections', 'value': 100},
 {'name': 'timeout', 'value': 30},
 {'name': 'debug_mode', 'value': False}]

[localhost] TASK: Start configuration (debug)> p config_items | length
3

[localhost] TASK: Start configuration (debug)> c
```

**Task 2 - Process configuration (first iteration):**

```
[localhost] TASK: Process configuration items (debug)> p item
{'name': 'max_connections', 'value': 100}

[localhost] TASK: Process configuration items (debug)> p item.name
'max_connections'

[localhost] TASK: Process configuration items (debug)> c
```

**Continue through remaining iterations and final task.**

---

## 📝 Exercise 5: Conditional Debugging

### Objective

Debug only specific hosts or conditions.

### Step 1: Create Multi-Host Playbook

```bash
cat > exercise5-conditional-debug.yml << 'EOF'
---
- name: Exercise 5 - Conditional Debugging
  hosts: webservers,dbservers
  debugger: never  # Default: no debugging
  
  vars:
    debug_host: "web1"  # Only debug this host
  
  tasks:
    - name: Task 1 - Normal execution
      debug:
        msg: "Running on {{ inventory_hostname }}"
    
    - name: Task 2 - Potential issue
      command: echo "Processing on {{ inventory_hostname }}"
      debugger: "{{ 'always' if inventory_hostname == debug_host else 'never' }}"
      register: process_result
    
    - name: Task 3 - Final step
      debug:
        msg: "Completed on {{ inventory_hostname }}: {{ process_result.stdout }}"
EOF
```

### Step 2: Run Playbook

```bash
ansible-playbook -i inventory.ini exercise5-conditional-debug.yml
```

### Step 3: Debug Session (only for web1)

```
TASK [Task 2 - Potential issue] ************************************************

[web1] TASK: Task 2 - Potential issue (debug)> p inventory_hostname
'web1'

[web1] TASK: Task 2 - Potential issue (debug)> p debug_host
'web1'

[web1] TASK: Task 2 - Potential issue (debug)> p task.args
{'_raw_params': 'echo "Processing on web1"'}

[web1] TASK: Task 2 - Potential issue (debug)> c
```

**Note:** db1 runs without debugging.

---

## 📝 Exercise 6: Production Debugging Pattern

### Objective

Implement a safe debugging pattern for production environments.

### Step 1: Create Production-Safe Playbook

```bash
cat > exercise6-production-debug.yml << 'EOF'
---
- name: Exercise 6 - Production Debugging
  hosts: local
  debugger: on_failed
  
  vars:
    environment: "production"
    enable_debug: false  # Set via command line: -e "enable_debug=true"
  
  tasks:
    - name: Pre-deployment checks
      block:
        - name: Check disk space
          shell: df -h / | tail -1 | awk '{print $5}' | sed 's/%//'
          register: disk_usage
        
        - name: Verify disk space
          assert:
            that:
              - disk_usage.stdout | int < 90
            fail_msg: "Disk usage too high: {{ disk_usage.stdout }}%"
            success_msg: "Disk space OK: {{ disk_usage.stdout }}%"
          debugger: "{{ 'always' if enable_debug else 'on_failed' }}"
        
        - name: Check service status
          command: echo "Service check placeholder"
          register: service_check
        
        - name: Verify service is running
          assert:
            that:
              - service_check.rc == 0
            fail_msg: "Service check failed"
          debugger: "{{ 'always' if enable_debug else 'on_failed' }}"
      
      rescue:
        - name: Handle pre-deployment failure
          debug:
            msg: "Pre-deployment checks failed, aborting deployment"
          debugger: always  # Always debug failures
        
        - name: Send alert
          debug:
            msg: "ALERT: Deployment aborted for {{ inventory_hostname }}"
          debugger: never  # Don't debug alerts
        
        - name: Fail the play
          fail:
            msg: "Deployment aborted due to failed pre-checks"
    
    - name: Deployment tasks (only if pre-checks pass)
      debug:
        msg: "Proceeding with deployment..."
EOF
```

### Step 2: Run in Normal Mode

```bash
ansible-playbook -i inventory.ini exercise6-production-debug.yml
```

### Step 3: Run with Debug Enabled

```bash
ansible-playbook -i inventory.ini exercise6-production-debug.yml -e "enable_debug=true"
```

### Expected Debug Session

```
TASK [Verify disk space] *******************************************************
[localhost] TASK: Verify disk space (debug)> p disk_usage.stdout
'45'

[localhost] TASK: Verify disk space (debug)> p disk_usage.stdout | int < 90
True

[localhost] TASK: Verify disk space (debug)> c

TASK [Verify service is running] ***********************************************
[localhost] TASK: Verify service is running (debug)> p service_check.rc
0

[localhost] TASK: Verify service is running (debug)> c
```

---

## 🎓 Challenge Exercises

### Challenge 1: Debug Loop Failures

Create a playbook that processes a list of files. Use the debugger to identify which file is causing issues and fix it interactively.

```bash
cat > challenge1-loop-debug.yml << 'EOF'
---
- name: Challenge 1 - Debug Loop Issues
  hosts: local
  debugger: on_failed
  
  vars:
    files_to_process:
      - name: "config.yml"
        path: "/tmp/configs/config.yml"
        required: true
      - name: "settings.ini"
        path: "/tmp/configs/settings.ini"
        required: false
      - name: "database.conf"
        path: "/nonexistent/database.conf"  # This will fail
        required: true
  
  tasks:
    - name: Process configuration files
      stat:
        path: "{{ item.path }}"
      loop: "{{ files_to_process }}"
      register: file_stats
      when: item.required
EOF
```

**Hint:** Use `p item` and `p item.path` to identify the problematic file.

### Challenge 2: Debug Complex Variable Interpolation

Create a playbook with nested variables and debug the interpolation:

```bash
cat > challenge2-variable-interpolation.yml << 'EOF'
---
- name: Challenge 2 - Complex Variables
  hosts: local
  debugger: on_failed
  
  vars:
    environments:
      development:
        db_host: "dev-db.local"
        db_port: 5432
      production:
        db_host: "prod-db.example.com"
        db_port: 5432
    
    current_env: "production"
    connection_string: "postgresql://{{ environments[current_env].db_host }}:{{ environments[current_env].db_port }}/mydb"
  
  tasks:
    - name: Display connection info
      debug:
        msg: "Connecting to: {{ connection_string }}"
    
    - name: Test undefined environment
      debug:
        msg: "{{ environments[undefined_env].db_host }}"
EOF
```

### Challenge 3: Production Deployment Debugger

Create a complete deployment playbook with proper debugging at critical points.

---

## ✅ Lab Validation

Run this validation playbook to check your progress:

```bash
cat > validate-lab4.yml << 'EOF'
---
- name: Validate Lab 4 - Debugger
  hosts: local
  gather_facts: no
  
  tasks:
    - name: Check exercise files exist
      stat:
        path: "{{ item }}"
      loop:
        - exercise1-basic-debug.yml
        - exercise2-variable-debug.yml
        - exercise3-deployment-debug.yml
        - exercise4-always-debug.yml
        - exercise5-conditional-debug.yml
        - exercise6-production-debug.yml
      register: exercise_files
    
    - name: Verify all exercises created
      assert:
        that:
          - item.stat.exists
        fail_msg: "Missing exercise file: {{ item.item }}"
      loop: "{{ exercise_files.results }}"
    
    - name: Check deployment artifacts
      stat:
        path: "{{ item }}"
      loop:
        - /tmp/test-app
        - /tmp/deployments/webapp/current
      register: artifacts
    
    - name: Verify deployments completed
      assert:
        that:
          - item.stat.exists
        fail_msg: "Missing artifact: {{ item.item }}"
      loop: "{{ artifacts.results }}"
    
    - name: Lab 4 completed successfully
      debug:
        msg: "✅ All Lab 4 exercises completed! Great work on mastering the debugger!"
EOF

ansible-playbook -i inventory.ini validate-lab4.yml
```

---

## 🎯 Key Takeaways

1. **Enable debugger** with `debugger: on_failed` for automatic debugging
2. Use `p` command to inspect variables and task state
3. Use `task.args` to view and modify task parameters
4. Use `redo` to retry tasks after making fixes
5. Use conditional debugging for production safety
6. Debugger is essential for troubleshooting complex playbooks
7. Combine debugger with check mode for safe testing

---

## 📚 Additional Resources

- [Ansible Debugger Documentation](https://docs.ansible.com/ansible/latest/user_guide/playbooks_debugger.html)
- [Troubleshooting Guide](https://docs.ansible.com/ansible/latest/user_guide/playbooks_startnstep.html)
- Day 6 Lesson: `04-playbook-debugger.md`

---

## 🎓 What's Next?

After completing this lab, you should be able to:

- Debug failing playbooks interactively
- Inspect and modify variables during execution
- Troubleshoot complex deployment issues
- Use debugger strategically in production

**Ready for the next topic? Continue to `05-delegation-rolling-updates.md`! 🚀**
