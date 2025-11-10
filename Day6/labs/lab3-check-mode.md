# Lab 3: Check Mode ("Dry Run") Testing

## 🎯 Lab Objectives

In this lab, you will:

- Use check mode to test playbooks safely
- Use diff mode to see file changes
- Create check-mode-aware playbooks
- Handle check mode limitations
- Validate configurations before deployment
- Test production-critical changes safely

## ⏱️ Estimated Time

60 minutes

## 📋 Prerequisites

- Completed Day 1-5 lessons and Labs 1-2
- Access to your OpenStack instance or test servers
- Ansible 2.9 or higher installed
- Basic understanding of playbook execution

## 🏗️ Lab Environment Setup

### Create Lab Directory

```bash
mkdir -p ~/ansible-labs/day6-lab3/{playbooks,files,inventory}
cd ~/ansible-labs/day6-lab3
```

### Create Inventory

```bash
cat > inventory/hosts.ini <<EOF
[local]
localhost ansible_connection=local

[testservers]
test1 ansible_host=localhost ansible_connection=local

# For OpenStack instance
[openstack]
# web1 ansible_host=<your-instance-ip> ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/openstack_key

[all:vars]
ansible_python_interpreter=/usr/bin/python3
EOF
```

### Create Test Files

```bash
# Create a sample configuration file
cat > files/app.conf <<EOF
# Application Configuration
server_name=testapp
port=8080
debug=false
max_connections=100
EOF

# Create test web page
cat > files/index.html <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>Test Page</title>
</head>
<body>
    <h1>Original Version</h1>
    <p>This is the original test page.</p>
</body>
</html>
EOF
```

---

## 📝 Exercise 1: Basic Check Mode

### Step 1: Create Simple Playbook

Create `playbooks/01-basic-check.yml`:

```yaml
---
- name: Basic Check Mode Example
  hosts: local
  gather_facts: yes
  
  tasks:
    - name: Create test directory
      file:
        path: /tmp/check_mode_test
        state: directory
        mode: '0755'
    
    - name: Create test file
      copy:
        content: |
          Test file created at {{ ansible_date_time.iso8601 }}
          Hostname: {{ ansible_hostname }}
        dest: /tmp/check_mode_test/info.txt
        mode: '0644'
    
    - name: Create multiple files
      file:
        path: "/tmp/check_mode_test/file{{ item }}.txt"
        state: touch
        mode: '0644'
      loop: [1, 2, 3, 4, 5]
    
    - name: Display message
      debug:
        msg: |
          {% if ansible_check_mode %}
          🔍 CHECK MODE: Would create files in /tmp/check_mode_test/
          {% else %}
          ✅ Files created in /tmp/check_mode_test/
          {% endif %}
```

### Step 2: Run in Check Mode

```bash
# Run in check mode (no changes made)
ansible-playbook -i inventory/hosts.ini playbooks/01-basic-check.yml --check

# Check if files were created (they shouldn't be)
ls -la /tmp/check_mode_test 2>/dev/null || echo "Directory does not exist (as expected)"
```

**Expected Output:**

```
TASK [Create test directory] *******************
changed: [localhost]

TASK [Create test file] ************************
changed: [localhost]

TASK [Create multiple files] *******************
changed: [localhost] => (item=1)
changed: [localhost] => (item=2)
changed: [localhost] => (item=3)
changed: [localhost] => (item=4)
changed: [localhost] => (item=5)

TASK [Display message] *************************
ok: [localhost] => {
    "msg": "🔍 CHECK MODE: Would create files in /tmp/check_mode_test/"
}

PLAY RECAP *************************************
localhost : ok=4    changed=3
```

### Step 3: Run Without Check Mode

```bash
# Run for real
ansible-playbook -i inventory/hosts.ini playbooks/01-basic-check.yml

# Verify files were created
ls -la /tmp/check_mode_test/
```

**Expected Output:**

```
TASK [Display message] *************************
ok: [localhost] => {
    "msg": "✅ Files created in /tmp/check_mode_test/"
}

# Files now exist:
total 8
drwxr-xr-x  8 user  wheel  256 Nov 10 10:30 .
drwxrwxrwt 12 root  wheel  384 Nov 10 10:30 ..
-rw-r--r--  1 user  wheel    0 Nov 10 10:30 file1.txt
-rw-r--r--  1 user  wheel    0 Nov 10 10:30 file2.txt
...
```

---

## 📝 Exercise 2: Diff Mode for File Changes

### Step 1: Create Configuration Update Playbook

Create `playbooks/02-diff-mode.yml`:

```yaml
---
- name: Configuration Updates with Diff
  hosts: local
  gather_facts: yes
  
  tasks:
    - name: Ensure test directory exists
      file:
        path: /tmp/check_mode_test
        state: directory
        mode: '0755'
      check_mode: no  # Always create directory
    
    - name: Create initial configuration
      copy:
        content: |
          # Initial Configuration
          server_name=localhost
          port=8080
          debug=true
          timeout=30
        dest: /tmp/check_mode_test/config.ini
        mode: '0644'
      check_mode: no  # Create initial file
    
    - name: Update server name
      lineinfile:
        path: /tmp/check_mode_test/config.ini
        regexp: '^server_name='
        line: 'server_name=production-server'
        backup: yes
    
    - name: Update port
      lineinfile:
        path: /tmp/check_mode_test/config.ini
        regexp: '^port='
        line: 'port=9090'
        backup: yes
    
    - name: Disable debug mode
      lineinfile:
        path: /tmp/check_mode_test/config.ini
        regexp: '^debug='
        line: 'debug=false'
        backup: yes
    
    - name: Add new setting
      lineinfile:
        path: /tmp/check_mode_test/config.ini
        line: 'max_connections=100'
        create: no
    
    - name: Show final configuration (when not in check mode)
      command: cat /tmp/check_mode_test/config.ini
      register: final_config
      changed_when: false
      when: not ansible_check_mode
    
    - name: Display configuration
      debug:
        msg: |
          {% if ansible_check_mode %}
          🔍 CHECK MODE: Configuration would be updated
          {% else %}
          Final Configuration:
          {{ final_config.stdout }}
          {% endif %}
```

### Step 2: Run with Diff Mode

```bash
# First run to create initial config
ansible-playbook -i inventory/hosts.ini playbooks/02-diff-mode.yml

# Now run in check mode with diff to see what would change
ansible-playbook -i inventory/hosts.ini playbooks/02-diff-mode.yml --check --diff
```

**Expected Output:**

```
TASK [Update server name] **********************
--- before: /tmp/check_mode_test/config.ini
+++ after: /tmp/check_mode_test/config.ini
@@ -1,4 +1,4 @@
 # Initial Configuration
-server_name=localhost
+server_name=production-server
 port=8080
 debug=true

changed: [localhost]

TASK [Update port] *****************************
--- before: /tmp/check_mode_test/config.ini
+++ after: /tmp/check_mode_test/config.ini
@@ -1,4 +1,4 @@
 # Initial Configuration
 server_name=production-server
-port=8080
+port=9090
 debug=true

changed: [localhost]
```

**📊 Analysis:**
- Diff shows exactly what lines change
- No actual modifications made
- Perfect for reviewing changes before applying

---

## 📝 Exercise 3: Check Mode Aware Playbook

### Step 1: Create Advanced Check Mode Playbook

Create `playbooks/03-check-mode-aware.yml`:

```yaml
---
- name: Check Mode Aware Tasks
  hosts: local
  gather_facts: yes
  
  vars:
    work_dir: /tmp/check_mode_test
  
  tasks:
    # Always run - information gathering
    - name: Check current system state
      command: uname -a
      register: system_info
      check_mode: no
      changed_when: false
    
    - name: Display system info
      debug:
        msg: "System: {{ system_info.stdout }}"
      check_mode: no
    
    - name: Check if work directory exists
      stat:
        path: "{{ work_dir }}"
      register: dir_exists
      check_mode: no
    
    - name: Show directory status
      debug:
        msg: |
          Directory status:
          Exists: {{ dir_exists.stat.exists }}
          {% if ansible_check_mode %}
          Mode: CHECK - would create if missing
          {% else %}
          Mode: EXECUTE - will create if missing
          {% endif %}
      check_mode: no
    
    # Respects check mode
    - name: Create work directory
      file:
        path: "{{ work_dir }}"
        state: directory
        mode: '0755'
      register: dir_created
    
    - name: Create data file
      copy:
        content: |
          Data generated at: {{ ansible_date_time.iso8601 }}
          Mode: {{ 'CHECK' if ansible_check_mode else 'EXECUTE' }}
          Hostname: {{ ansible_hostname }}
        dest: "{{ work_dir }}/data.txt"
        mode: '0644'
      register: file_created
    
    # Conditional based on check mode
    - name: Read created file (only in execute mode)
      slurp:
        src: "{{ work_dir }}/data.txt"
      register: file_content
      when: not ansible_check_mode
    
    - name: Display file content (execute mode)
      debug:
        msg: "{{ file_content.content | b64decode }}"
      when: 
        - not ansible_check_mode
        - file_content.content is defined
    
    - name: Show what would happen (check mode)
      debug:
        msg: |
          🔍 CHECK MODE SUMMARY
          =====================
          Would create directory: {{ dir_created.changed }}
          Would create file: {{ file_created.changed }}
          Would write content with timestamp: {{ ansible_date_time.iso8601 }}
      when: ansible_check_mode
    
    # Task that should never run in check mode
    - name: Execute external command (skip in check mode)
      command: echo "This runs only in execute mode"
      register: command_output
      changed_when: false
      when: not ansible_check_mode
    
    - name: Show command result
      debug:
        msg: "{{ command_output.stdout }}"
      when: 
        - not ansible_check_mode
        - command_output.stdout is defined
```

### Step 2: Test Check Mode Awareness

```bash
# Run in check mode
ansible-playbook -i inventory/hosts.ini playbooks/03-check-mode-aware.yml --check -v

# Run in execute mode
ansible-playbook -i inventory/hosts.ini playbooks/03-check-mode-aware.yml -v
```

**Compare outputs:**

Check mode shows:
```
TASK [Show what would happen (check mode)] *****
ok: [localhost] => {
    "msg": "🔍 CHECK MODE SUMMARY..."
}

TASK [Execute external command] ****************
skipping: [localhost]  # Skipped in check mode
```

Execute mode shows:
```
TASK [Display file content (execute mode)] *****
ok: [localhost] => {
    "msg": "Data generated at: 2024-11-10T10:45:30Z..."
}

TASK [Execute external command] ****************
ok: [localhost]
```

---

## 📝 Exercise 4: Safe Production Deployment

### Step 1: Create Production-Safe Playbook

Create `playbooks/04-safe-deployment.yml`:

```yaml
---
- name: Safe Production Deployment
  hosts: local
  become: yes
  
  vars:
    app_root: /opt/testapp
    config_file: "{{ app_root }}/config.json"
    require_check_first: true
  
  tasks:
    # Safety validation
    - name: Enforce check mode first run
      assert:
        that:
          - ansible_check_mode or not require_check_first
        fail_msg: |
          ⚠️  SAFETY VIOLATION!
          You must run this playbook in check mode first:
          ansible-playbook playbook.yml --check --diff
          
          Then run with: -e "require_check_first=false"
        success_msg: "✅ Safety check passed"
      check_mode: no
    
    # Always run - gather information
    - name: Check if application exists
      stat:
        path: "{{ app_root }}"
      register: app_exists
      check_mode: no
    
    - name: Display current state
      debug:
        msg: |
          Current State:
          Application exists: {{ app_exists.stat.exists }}
          {% if app_exists.stat.exists %}
          Last modified: {{ app_exists.stat.mtime }}
          {% endif %}
          
          {% if ansible_check_mode %}
          🔍 Running in CHECK MODE - no changes will be made
          {% else %}
          ⚠️  Running in EXECUTE MODE - changes will be applied!
          {% endif %}
      check_mode: no
    
    # Create application structure
    - name: Create application directory
      file:
        path: "{{ app_root }}"
        state: directory
        mode: '0755'
    
    - name: Create subdirectories
      file:
        path: "{{ app_root }}/{{ item }}"
        state: directory
        mode: '0755'
      loop:
        - bin
        - config
        - data
        - logs
    
    - name: Deploy application configuration
      copy:
        content: |
          {
            "app_name": "TestApp",
            "version": "2.0.0",
            "port": 8080,
            "debug": false,
            "database": {
              "host": "localhost",
              "port": 5432,
              "name": "testapp_db"
            },
            "deployed_at": "{{ ansible_date_time.iso8601 }}",
            "deployed_by": "{{ ansible_user_id }}"
          }
        dest: "{{ config_file }}"
        mode: '0644'
        backup: yes
    
    - name: Create application script
      copy:
        content: |
          #!/bin/bash
          # TestApp v2.0.0
          echo "Starting TestApp..."
          echo "Config: {{ config_file }}"
          echo "Mode: {{ 'CHECK' if ansible_check_mode else 'EXECUTE' }}"
        dest: "{{ app_root }}/bin/start.sh"
        mode: '0755'
    
    - name: Create log file
      copy:
        content: |
          Application Deployment Log
          ==========================
          Date: {{ ansible_date_time.iso8601 }}
          Mode: {{ 'CHECK' if ansible_check_mode else 'EXECUTE' }}
          User: {{ ansible_user_id }}
          Host: {{ ansible_hostname }}
        dest: "{{ app_root }}/logs/deployment.log"
        mode: '0644'
    
    # Verification (only in execute mode)
    - name: Verify deployment
      stat:
        path: "{{ item }}"
      loop:
        - "{{ app_root }}/bin/start.sh"
        - "{{ config_file }}"
        - "{{ app_root }}/logs/deployment.log"
      register: deployed_files
      check_mode: no
      when: not ansible_check_mode
    
    - name: Deployment summary
      debug:
        msg: |
          {% if ansible_check_mode %}
          🔍 CHECK MODE COMPLETE
          ======================
          Review the changes above.
          If acceptable, run again with:
          ansible-playbook playbook.yml -e "require_check_first=false"
          {% else %}
          ✅ DEPLOYMENT COMPLETE
          =====================
          Application: {{ app_root }}
          Configuration: {{ config_file }}
          
          Verify with:
          ls -la {{ app_root }}
          cat {{ config_file }}
          {% endif %}
      check_mode: no
```

### Step 2: Safe Deployment Process

```bash
# Step 1: REQUIRED - Run in check mode first
ansible-playbook -i inventory/hosts.ini playbooks/04-safe-deployment.yml --check --diff

# Step 2: Review the output carefully
# Check all changes shown in diff output

# Step 3: If changes look good, run for real
ansible-playbook -i inventory/hosts.ini playbooks/04-safe-deployment.yml -e "require_check_first=false"

# Step 4: Verify deployment
ls -la /opt/testapp/
cat /opt/testapp/config.json
```

**Expected Check Mode Output:**

```
TASK [Enforce check mode first run] ************
ok: [localhost] => {
    "msg": "✅ Safety check passed"
}

TASK [Display current state] *******************
ok: [localhost] => {
    "msg": "🔍 Running in CHECK MODE - no changes will be made"
}

TASK [Create application directory] ************
changed: [localhost]

TASK [Deploy application configuration] ********
--- before
+++ after
@@ -0,0 +1,15 @@
+{
+  "app_name": "TestApp",
+  "version": "2.0.0",
...

changed: [localhost]
```

---

## 📝 Exercise 5: Check Mode Limitations

### Step 1: Understanding Limitations

Create `playbooks/05-check-mode-limitations.yml`:

```yaml
---
- name: Check Mode Limitations Demo
  hosts: local
  
  tasks:
    # Limitation 1: Commands don't run in check mode
    - name: Command module limitation
      command: echo "test" > /tmp/command_output.txt
      changed_when: true
    
    - name: Try to read command output (will fail in check mode)
      command: cat /tmp/command_output.txt
      register: output
      failed_when: false
      changed_when: false
    
    - name: Show output issue
      debug:
        msg: |
          {% if ansible_check_mode %}
          ⚠️  In check mode: file doesn't exist yet
          Output: {{ output.stdout | default('File not found') }}
          {% else %}
          Output: {{ output.stdout }}
          {% endif %}
    
    # Limitation 2: Task dependencies
    - name: Create dependency file
      copy:
        content: "dependency_data"
        dest: /tmp/dependency.txt
      register: dep_created
    
    - name: Read dependency (problematic in check mode)
      slurp:
        src: /tmp/dependency.txt
      register: dep_content
      failed_when: false
    
    - name: Handle dependency issue
      debug:
        msg: |
          {% if ansible_check_mode and not dep_content.content is defined %}
          ⚠️  Check mode: file would be created but can't be read yet
          {% elif dep_content.content is defined %}
          Content: {{ dep_content.content | b64decode }}
          {% else %}
          ❌ Error reading file
          {% endif %}
    
    # Solution: Use check_mode flag
    - name: Workaround - always create file
      copy:
        content: "workaround_data"
        dest: /tmp/workaround.txt
      check_mode: no  # Always create
    
    - name: Now we can read it
      slurp:
        src: /tmp/workaround.txt
      register: workaround_content
      check_mode: no
    
    - name: Show workaround success
      debug:
        msg: "✅ Workaround content: {{ workaround_content.content | b64decode }}"
      check_mode: no
```

### Step 2: Run and Observe Limitations

```bash
# Run in check mode - see limitations
ansible-playbook -i inventory/hosts.ini playbooks/05-check-mode-limitations.yml --check -v

# Run in execute mode - see it work properly
ansible-playbook -i inventory/hosts.ini playbooks/05-check-mode-limitations.yml -v
```

---

## ✅ Lab Validation

### Create Validation Playbook

Create `playbooks/validate-lab3.yml`:

```yaml
---
- name: Validate Lab 3 Completion
  hosts: local
  gather_facts: yes
  
  tasks:
    - name: Check test directory exists
      stat:
        path: /tmp/check_mode_test
      register: test_dir
    
    - name: Check config file exists
      stat:
        path: /tmp/check_mode_test/config.ini
      register: config_file
    
    - name: Check application directory
      stat:
        path: /opt/testapp
      register: app_dir
      become: yes
    
    - name: Test check mode variable awareness
      debug:
        msg: "Check mode: {{ ansible_check_mode }}"
      check_mode: no
    
    - name: Validation Results
      debug:
        msg: |
          Lab 3 Validation Results
          ========================
          ✅ Test directory exists: {{ test_dir.stat.exists }}
          ✅ Config file created: {{ config_file.stat.exists }}
          ✅ Application deployed: {{ app_dir.stat.exists }}
          ✅ Check mode awareness: Working
          
          {% if test_dir.stat.exists and config_file.stat.exists and app_dir.stat.exists %}
          🎉 All checks passed! Lab 3 completed successfully!
          {% else %}
          ⚠️  Some validations failed. Review the playbook execution.
          {% endif %}
```

Run validation:

```bash
# Validate in check mode (should work)
ansible-playbook -i inventory/hosts.ini playbooks/validate-lab3.yml --check

# Validate in execute mode
ansible-playbook -i inventory/hosts.ini playbooks/validate-lab3.yml
```

---

## 🎓 What You Learned

- ✅ Used `--check` flag to test playbooks safely
- ✅ Used `--diff` to see exact file changes
- ✅ Created check-mode-aware playbooks
- ✅ Handled check mode limitations
- ✅ Implemented safety checks in production playbooks
- ✅ Tested configurations before deployment

---

## 🚀 Challenge Exercises

### Challenge 1: Pre-Production Validation

Create a playbook that:
- Validates all configurations in check mode
- Generates a report of changes
- Requires approval before execution
- Logs all check mode runs

### Challenge 2: Configuration Diff Reporter

Create a playbook that:
- Runs in check mode
- Captures all diffs
- Emails summary to administrators
- Creates change documentation

### Challenge 3: Safe Database Migration

Create a playbook that:
- Tests migrations in check mode
- Validates schema changes
- Requires check mode success
- Backs up before execution

---

## 📚 Additional Resources

- [Check Mode Documentation](https://docs.ansible.com/ansible/latest/user_guide/playbooks_checkmode.html)
- [Diff Mode](https://docs.ansible.com/ansible/latest/user_guide/playbooks_checkmode.html#showing-differences-with-diff)
- [Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)

---

## 🔄 Clean Up

```bash
# Remove test files
rm -rf /tmp/check_mode_test
sudo rm -rf /opt/testapp

# Keep playbooks for reference
```

---

**Congratulations! You've completed Lab 3! 🎉**

Next: Move on to Topic 4 - Playbook Debugger
