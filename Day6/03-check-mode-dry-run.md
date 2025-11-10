# Topic 3: Check Mode ("Dry Run")

## 📚 Overview

Check mode (also known as "dry run") allows you to test what changes Ansible would make without actually making them. This is essential for validating playbooks before running them in production, testing configurations, and understanding the impact of changes.

### 🎯 Learning Objectives

By the end of this lesson, you will:

- ✅ Understand check mode and its limitations
- ✅ Use `--check` flag effectively
- ✅ Implement check mode in playbooks
- ✅ Handle check mode with conditional logic
- ✅ Use diff mode to see changes
- ✅ Create check-mode-aware tasks
- ✅ Test playbooks safely before production runs

### ⏱️ Estimated Time

- Theory: 30 minutes
- Lab: 30 minutes
- Total: 60 minutes

---

## 🔍 What is Check Mode?

Check mode runs through playbook tasks and reports what **would** change, without actually making those changes.

### Basic Usage

```bash
# Run playbook in check mode
ansible-playbook playbook.yml --check

# Check mode with diff (show file changes)
ansible-playbook playbook.yml --check --diff

# Short form
ansible-playbook playbook.yml -C -D
```

### What Check Mode Does

- ✅ Shows which tasks would change
- ✅ Reports expected modifications
- ✅ Validates playbook syntax
- ✅ Tests conditionals and logic
- ❌ Does NOT make actual changes
- ❌ Cannot test some modules accurately

---

## 🎯 Basic Check Mode Example

```yaml
---
- name: Check Mode Example
  hosts: webservers
  become: yes
  
  tasks:
    - name: Install nginx
      apt:
        name: nginx
        state: present
    
    - name: Copy configuration
      copy:
        src: nginx.conf
        dest: /etc/nginx/nginx.conf
        backup: yes
    
    - name: Start nginx
      service:
        name: nginx
        state: started
        enabled: yes
```

**Run in check mode:**
```bash
ansible-playbook -i inventory.ini webserver.yml --check
```

**Output shows:**
```
TASK [Install nginx] ***************************
changed: [web1]  # Would install nginx

TASK [Copy configuration] **********************
changed: [web1]  # Would copy file

TASK [Start nginx] *****************************
ok: [web1]  # Already running (or would start)
```

---

## 🔧 Check Mode with Diff

See exactly what would change in files:

```yaml
---
- name: Configuration Update with Diff
  hosts: servers
  become: yes
  
  tasks:
    - name: Update SSH configuration
      lineinfile:
        path: /etc/ssh/sshd_config
        regexp: '^#?PermitRootLogin'
        line: 'PermitRootLogin no'
        backup: yes
```

**Run with diff:**
```bash
ansible-playbook config.yml --check --diff
```

**Output shows:**
```
TASK [Update SSH configuration] ****************
--- before: /etc/ssh/sshd_config
+++ after: /etc/ssh/sshd_config
@@ -32,1 +32,1 @@
-#PermitRootLogin yes
+PermitRootLogin no

changed: [server1]
```

---

## 🎨 Controlling Check Mode Behavior

### Always Run in Check Mode

Some tasks should always run in check mode (never make changes):

```yaml
---
- name: Safe validation tasks
  hosts: all
  
  tasks:
    - name: Check disk space (always safe)
      command: df -h
      check_mode: no  # Always run, even in check mode
      changed_when: false
    
    - name: This would modify files
      copy:
        content: "{{ ansible_date_time.iso8601 }}"
        dest: /tmp/timestamp.txt
      # Respects --check flag
```

### Never Run in Check Mode

Some tasks should skip check mode:

```yaml
- name: Get dynamic data (skip in check mode)
  uri:
    url: http://api.example.com/data
  register: api_data
  check_mode: no  # Must run to get data
```

### Check Mode Aware Tasks

```yaml
---
- name: Check Mode Aware Playbook
  hosts: servers
  
  tasks:
    - name: Gather information (safe in check mode)
      command: hostname
      register: hostname_result
      check_mode: no
      changed_when: false
    
    - name: Show hostname
      debug:
        msg: "Running on: {{ hostname_result.stdout }}"
      check_mode: no
    
    - name: Make changes (respects check mode)
      file:
        path: /tmp/testfile
        state: touch
        mode: '0644'
```

---

## 💡 Real-World Scenario: Safe Deployment

```yaml
---
- name: Safe Application Deployment
  hosts: appservers
  become: yes
  
  vars:
    app_version: "2.0.0"
    config_file: /etc/myapp/config.yml
  
  tasks:
    # Always run - gather facts
    - name: Check current version
      slurp:
        src: /opt/myapp/version.txt
      register: current_version
      check_mode: no
      failed_when: false
    
    - name: Display current state
      debug:
        msg: |
          Current version: {{ (current_version.content | b64decode).strip() if current_version.content is defined else 'None' }}
          Target version: {{ app_version }}
      check_mode: no
    
    # Would make changes
    - name: Stop application
      systemd:
        name: myapp
        state: stopped
    
    - name: Backup configuration
      copy:
        src: "{{ config_file }}"
        dest: "{{ config_file }}.backup"
        remote_src: yes
    
    - name: Update application files
      copy:
        src: "myapp-{{ app_version }}.tar.gz"
        dest: /tmp/myapp.tar.gz
    
    - name: Extract application
      unarchive:
        src: /tmp/myapp.tar.gz
        dest: /opt/myapp
        remote_src: yes
    
    - name: Update configuration
      template:
        src: config.yml.j2
        dest: "{{ config_file }}"
        backup: yes
    
    - name: Start application
      systemd:
        name: myapp
        state: started
    
    # Always run - verify
    - name: Wait for application
      wait_for:
        port: 8080
        delay: 5
        timeout: 30
      check_mode: no
      when: not ansible_check_mode
```

**Test before deploying:**
```bash
# Check what would change
ansible-playbook deploy.yml --check --diff

# Review changes, then run for real
ansible-playbook deploy.yml
```

---

## 🔍 Conditional Logic with Check Mode

```yaml
---
- name: Check Mode Conditional Logic
  hosts: all
  
  tasks:
    - name: Task that modifies system
      file:
        path: /tmp/important_file
        state: touch
      register: file_result
    
    - name: Only run if not in check mode
      debug:
        msg: "File was actually created"
      when: 
        - not ansible_check_mode
        - file_result.changed
    
    - name: Show what would happen in check mode
      debug:
        msg: "Would create file: /tmp/important_file"
      when: ansible_check_mode
    
    - name: Command that needs real execution
      command: some_command_that_cannot_run_in_check_mode
      when: not ansible_check_mode
```

---

## 🎯 Pattern: Pre-Deployment Validation

```yaml
---
- name: Pre-Deployment Validation
  hosts: webservers
  become: yes
  
  tasks:
    # Phase 1: Validation (always run)
    - name: Check if config file exists
      stat:
        path: /etc/nginx/nginx.conf
      register: config_exists
      check_mode: no
    
    - name: Fail if config missing
      fail:
        msg: "Configuration file not found!"
      when: not config_exists.stat.exists
      check_mode: no
    
    - name: Validate nginx configuration
      command: nginx -t
      register: nginx_validation
      failed_when: nginx_validation.rc != 0
      changed_when: false
      check_mode: no
    
    - name: Show validation result
      debug:
        msg: "✅ Configuration valid"
      when: nginx_validation.rc == 0
      check_mode: no
    
    # Phase 2: Changes (respect check mode)
    - name: Update nginx configuration
      template:
        src: nginx.conf.j2
        dest: /etc/nginx/nginx.conf
        validate: 'nginx -t -c %s'
        backup: yes
    
    - name: Reload nginx
      systemd:
        name: nginx
        state: reloaded
```

---

## 📊 Check Mode Limitations

### Modules That Don't Support Check Mode

Not all modules support check mode properly:

```yaml
# ❌ These may not work correctly in check mode
- name: Command module (unpredictable)
  command: /opt/custom_script.sh

- name: Shell module (unpredictable)
  shell: echo "test" > /tmp/file

- name: Raw module (no check mode support)
  raw: systemctl restart service
```

**Solution:** Use `check_mode: no` or conditional logic:

```yaml
- name: Run command only when not in check mode
  command: /opt/custom_script.sh
  when: not ansible_check_mode

# OR mark as check_mode safe
- name: Safe information gathering
  command: cat /etc/os-release
  check_mode: no
  changed_when: false
```

### Dependencies Between Tasks

```yaml
---
- name: Task Dependency Example
  hosts: servers
  
  tasks:
    # This creates a file in check mode
    - name: Create config file
      copy:
        content: "config_data"
        dest: /tmp/config.txt
      register: config_created
    
    # This tries to read the file (won't exist in check mode!)
    - name: Read config file
      slurp:
        src: /tmp/config.txt
      register: config_content
      check_mode: no
      failed_when: false  # Don't fail in check mode
    
    - name: Use config (handle check mode)
      debug:
        msg: "{{ config_content.content | b64decode if config_content.content is defined else 'Would be created' }}"
      check_mode: no
```

---

## 🛡️ Safe Testing Pattern

```yaml
---
- name: Safe Testing Pattern
  hosts: production
  become: yes
  
  vars:
    safety_check: true
  
  tasks:
    - name: Pre-flight safety check
      assert:
        that:
          - ansible_check_mode or safety_check
        fail_msg: |
          ⚠️  SAFETY CHECK FAILED!
          You must run in check mode first or set safety_check=false
        success_msg: "✅ Safety check passed"
      check_mode: no
    
    - name: Dangerous operation
      file:
        path: /important/production/data
        state: absent
      when: not safety_check
```

**Usage:**
```bash
# Step 1: Test in check mode (required)
ansible-playbook dangerous.yml --check

# Step 2: Run for real with safety override
ansible-playbook dangerous.yml -e "safety_check=false"
```

---

## 💡 Best Practices

### 1. Always Test with Check Mode First

```bash
# ❌ BAD - Run directly in production
ansible-playbook production-deploy.yml

# ✅ GOOD - Test first
ansible-playbook production-deploy.yml --check --diff
# Review changes
ansible-playbook production-deploy.yml
```

### 2. Use Diff Mode for File Changes

```bash
# See exactly what will change
ansible-playbook update-configs.yml --check --diff | tee check-output.txt
```

### 3. Mark Read-Only Tasks Appropriately

```yaml
# ✅ GOOD - Information gathering always safe
- name: Check system resources
  command: df -h
  register: disk_space
  check_mode: no
  changed_when: false
```

### 4. Handle Check Mode in Custom Scripts

```yaml
- name: Custom script with check mode awareness
  script: |
    #!/bin/bash
    if [ "$CHECK_MODE" = "True" ]; then
      echo "Would execute: $ACTION"
      exit 0
    fi
    # Actually execute
    $ACTION
  environment:
    CHECK_MODE: "{{ ansible_check_mode }}"
    ACTION: "systemctl restart myapp"
```

---

## 🔧 Practical Example: Database Migration

```yaml
---
- name: Database Migration with Check Mode
  hosts: dbservers
  become: yes
  
  vars:
    migration_version: "v2.0.0"
  
  tasks:
    # Always run - validation
    - name: Check database connectivity
      postgresql_query:
        db: postgres
        query: "SELECT version()"
      become_user: postgres
      register: db_version
      check_mode: no
      changed_when: false
    
    - name: Check current schema version
      postgresql_query:
        db: production_db
        query: "SELECT version FROM schema_migrations ORDER BY applied_at DESC LIMIT 1"
      become_user: postgres
      register: current_schema
      check_mode: no
      changed_when: false
    
    - name: Display current state
      debug:
        msg: |
          Database: {{ db_version.query_result[0].version }}
          Current Schema: {{ current_schema.query_result[0].version if current_schema.query_result | length > 0 else 'None' }}
          Target Schema: {{ migration_version }}
      check_mode: no
    
    # Respects check mode
    - name: Backup database before migration
      postgresql_db:
        name: production_db
        state: dump
        target: "/backup/pre_{{ migration_version }}_{{ ansible_date_time.epoch }}.sql"
      become_user: postgres
    
    - name: Run migration script
      postgresql_query:
        db: production_db
        path_to_script: "/migrations/{{ migration_version }}.sql"
      become_user: postgres
    
    - name: Update schema version
      postgresql_query:
        db: production_db
        query: "INSERT INTO schema_migrations (version, applied_at) VALUES ('{{ migration_version }}', NOW())"
      become_user: postgres
    
    # Always run - verification
    - name: Verify migration (in real run)
      postgresql_query:
        db: production_db
        query: "SELECT version FROM schema_migrations ORDER BY applied_at DESC LIMIT 1"
      become_user: postgres
      register: new_schema
      check_mode: no
      when: not ansible_check_mode
    
    - name: Show migration result
      debug:
        msg: |
          {% if ansible_check_mode %}
          🔍 CHECK MODE: Would migrate to {{ migration_version }}
          {% else %}
          ✅ Migration completed: {{ new_schema.query_result[0].version }}
          {% endif %}
      check_mode: no
```

**Test migration safely:**
```bash
# Step 1: Check what would happen
ansible-playbook migration.yml --check --diff

# Step 2: Review and run
ansible-playbook migration.yml
```

---

## 🎯 Advanced Pattern: Staged Rollout

```yaml
---
- name: Staged Rollout with Check Mode
  hosts: webservers
  serial: 1
  
  tasks:
    - name: Run in check mode on first host
      include_tasks: deploy_tasks.yml
      when: inventory_hostname == ansible_play_hosts[0]
      check_mode: yes
    
    - name: Pause for review
      pause:
        prompt: |
          Check mode completed on {{ ansible_play_hosts[0] }}.
          Review changes and press Enter to continue with real deployment.
      when: inventory_hostname == ansible_play_hosts[0]
    
    - name: Deploy to all hosts
      include_tasks: deploy_tasks.yml
```

---

## 📝 Summary

**Key Takeaways:**

1. **Check mode** tests playbooks without making changes
2. Use `--check` flag to run in dry-run mode
3. Use `--diff` to see file changes
4. Set `check_mode: no` for tasks that must always run
5. Use `ansible_check_mode` variable for conditional logic
6. Not all modules support check mode properly
7. Always test critical playbooks in check mode first

**Check Mode Workflow:**

1. Write/update playbook
2. Run with `--check --diff`
3. Review expected changes
4. Run without `--check`
5. Verify actual changes

**When to Use Check Mode:**

- ✅ Before production deployments
- ✅ Testing new playbooks
- ✅ Validating configuration changes
- ✅ Training and demonstrations
- ✅ CI/CD validation pipelines

**Next Steps:**

- Complete Lab 3: Check Mode Testing
- Practice safe deployment patterns
- Move on to Topic 4: Playbook Debugger

---

## 📖 Additional Resources

- [Official Docs: Check Mode](https://docs.ansible.com/ansible/latest/user_guide/playbooks_checkmode.html)
- [Validating Tasks](https://docs.ansible.com/ansible/latest/user_guide/playbooks_tests.html)
- [Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)

---

**Ready for hands-on practice? Head to `labs/lab3-check-mode.md`! 🚀**
