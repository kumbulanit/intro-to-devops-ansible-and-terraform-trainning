# Topic 4: Playbook Debugger

## 📚 Overview

The Ansible debugger provides interactive debugging capabilities for troubleshooting playbooks. It allows you to pause execution, inspect variables, modify values, and step through tasks—essential for diagnosing complex issues in production environments.

### 🎯 Learning Objectives

By the end of this lesson, you will:

- ✅ Enable and use the Ansible debugger
- ✅ Set breakpoints in playbooks
- ✅ Inspect variables and task results
- ✅ Debug failed tasks interactively
- ✅ Modify variables during execution
- ✅ Step through playbook execution
- ✅ Troubleshoot complex playbook issues

### ⏱️ Estimated Time

- Theory: 45 minutes
- Lab: 45 minutes
- Total: 90 minutes

---

## 🔧 Enabling the Debugger

### Method 1: Command Line

```bash
# Enable debugger for all failures
ANSIBLE_ENABLE_TASK_DEBUGGER=True ansible-playbook playbook.yml

# Or use environment variable
export ANSIBLE_ENABLE_TASK_DEBUGGER=True
ansible-playbook playbook.yml
```

### Method 2: Ansible Configuration

```ini
# ansible.cfg
[defaults]
enable_task_debugger = True
```

### Method 3: In Playbook

```yaml
---
- name: Playbook with debugger
  hosts: servers
  debugger: on_failed  # Options: never, always, on_failed, on_unreachable, on_skipped
  
  tasks:
    - name: Task that might fail
      command: /bin/false
```

---

## 🎯 Debugger Activation Modes

### on_failed (Most Common)

Debug only when tasks fail:

```yaml
---
- name: Debug on failure
  hosts: servers
  debugger: on_failed
  
  tasks:
    - name: This will fail
      command: /bin/false
      # Debugger activates here
```

### always

Debug every task:

```yaml
---
- name: Debug everything
  hosts: servers
  debugger: always  # Enters debugger for every task
  
  tasks:
    - name: First task
      debug:
        msg: "Step 1"
    
    - name: Second task
      debug:
        msg: "Step 2"
```

### Task-Level Debugger

Enable debugger for specific tasks:

```yaml
---
- name: Selective debugging
  hosts: servers
  
  tasks:
    - name: Normal task
      command: echo "runs normally"
    
    - name: Debug this task
      command: /opt/complex_script.sh
      debugger: always  # Only this task
    
    - name: Another normal task
      command: echo "runs normally"
```

---

## 🎮 Debugger Commands

When in debugger prompt `(debug)`, use these commands:

| Command | Shortcut | Description |
|---------|----------|-------------|
| `print` | `p` | Print variable value |
| `task` | `t` | Display current task |
| `task.args` | `t.args` | Show task arguments |
| `vars` | `v` | Show all variables |
| `result` | `r` | Show task result |
| `continue` | `c` | Continue execution |
| `quit` | `q` | Quit debugger (fail task) |
| `redo` | `rd` | Run task again |
| `update_task` | `u` | Modify task arguments |

---

## 💡 Basic Debugging Example

```yaml
---
- name: Basic Debugger Example
  hosts: localhost
  debugger: on_failed
  
  vars:
    username: "testuser"
    config_path: "/etc/myapp/config.yml"
  
  tasks:
    - name: Create user
      user:
        name: "{{ username }}"
        state: present
    
    - name: This will fail
      command: cat {{ config_path }}
      # File doesn't exist, debugger activates
```

**Debug session:**

```
TASK [This will fail] ******************
fatal: [localhost]: FAILED! => {"changed": true, "cmd": ["cat", "/etc/myapp/config.yml"], "msg": "non-zero return code", "rc": 1}

[localhost] TASK: This will fail (debug)> p result
{'changed': True,
 'cmd': ['cat', '/etc/myapp/config.yml'],
 'msg': 'non-zero return code',
 'rc': 1,
 'stderr': 'cat: /etc/myapp/config.yml: No such file or directory'}

[localhost] TASK: This will fail (debug)> p config_path
'/etc/myapp/config.yml'

[localhost] TASK: This will fail (debug)> p task.args
{'_raw_params': 'cat /etc/myapp/config.yml'}

[localhost] TASK: This will fail (debug)> c
```

---

## 🔍 Inspecting Variables

### Print Simple Variables

```yaml
---
- name: Variable Inspection
  hosts: localhost
  debugger: always
  
  vars:
    app_name: "myapp"
    app_version: "2.0.0"
    app_port: 8080
  
  tasks:
    - name: Deploy application
      debug:
        msg: "Deploying {{ app_name }} v{{ app_version }}"
```

**Debug session:**

```
[localhost] TASK: Deploy application (debug)> p app_name
'myapp'

[localhost] TASK: Deploy application (debug)> p app_version
'2.0.0'

[localhost] TASK: Deploy application (debug)> p app_port
8080
```

### Print Complex Variables

```yaml
---
- name: Complex Variables
  hosts: localhost
  debugger: always
  
  vars:
    database:
      host: "db.example.com"
      port: 5432
      name: "production_db"
      users:
        - name: "app_user"
          privileges: "SELECT,INSERT,UPDATE"
        - name: "admin_user"
          privileges: "ALL"
  
  tasks:
    - name: Configure database
      debug:
        msg: "Setting up database"
```

**Debug session:**

```
[localhost] TASK: Configure database (debug)> p database
{'host': 'db.example.com',
 'name': 'production_db',
 'port': 5432,
 'users': [{'name': 'app_user', 'privileges': 'SELECT,INSERT,UPDATE'},
           {'name': 'admin_user', 'privileges': 'ALL'}]}

[localhost] TASK: Configure database (debug)> p database['host']
'db.example.com'

[localhost] TASK: Configure database (debug)> p database['users'][0]['name']
'app_user'
```

### Print Ansible Facts

```
[localhost] TASK: task_name (debug)> p ansible_hostname
'web-server-01'

[localhost] TASK: task_name (debug)> p ansible_distribution
'Ubuntu'

[localhost] TASK: task_name (debug)> p ansible_default_ipv4.address
'192.168.1.100'
```

---

## 🛠️ Modifying Task Arguments

### Update Task Parameters

```yaml
---
- name: Modify Task Example
  hosts: localhost
  debugger: on_failed
  
  tasks:
    - name: Copy file with wrong path
      copy:
        src: /wrong/path/file.txt
        dest: /tmp/file.txt
```

**Debug session:**

```
[localhost] TASK: Copy file with wrong path (debug)> p task.args
{'dest': '/tmp/file.txt', 'src': '/wrong/path/file.txt'}

[localhost] TASK: Copy file with wrong path (debug)> task.args['src'] = '/correct/path/file.txt'

[localhost] TASK: Copy file with wrong path (debug)> p task.args
{'dest': '/tmp/file.txt', 'src': '/correct/path/file.txt'}

[localhost] TASK: Copy file with wrong path (debug)> redo
```

---

## 🎯 Real-World Debugging Scenario

### Debugging Complex Deployment

```yaml
---
- name: Complex Deployment with Debugging
  hosts: appservers
  become: yes
  debugger: on_failed
  
  vars:
    app_version: "2.5.0"
    app_root: "/opt/myapp"
    config_template: "config.yml.j2"
    required_packages:
      - python3
      - python3-pip
      - nginx
  
  tasks:
    - name: Install required packages
      apt:
        name: "{{ required_packages }}"
        state: present
        update_cache: yes
    
    - name: Create application directory
      file:
        path: "{{ app_root }}"
        state: directory
        mode: '0755'
    
    - name: Download application
      get_url:
        url: "https://releases.example.com/myapp-{{ app_version }}.tar.gz"
        dest: "/tmp/myapp-{{ app_version }}.tar.gz"
      register: download_result
    
    - name: Extract application
      unarchive:
        src: "/tmp/myapp-{{ app_version }}.tar.gz"
        dest: "{{ app_root }}"
        remote_src: yes
    
    - name: Deploy configuration
      template:
        src: "{{ config_template }}"
        dest: "{{ app_root }}/config.yml"
        validate: 'python3 -c "import yaml; yaml.safe_load(open(\"%s\"))"'
      register: config_result
    
    - name: Install Python dependencies
      pip:
        requirements: "{{ app_root }}/requirements.txt"
        executable: pip3
    
    - name: Start application
      systemd:
        name: myapp
        state: started
        enabled: yes
```

**Debug session when download fails:**

```
TASK [Download application] ************
fatal: [app1]: FAILED! => {"msg": "Request failed", "status_code": 404}

[app1] TASK: Download application (debug)> p app_version
'2.5.0'

[app1] TASK: Download application (debug)> p task.args
{'dest': '/tmp/myapp-2.5.0.tar.gz',
 'url': 'https://releases.example.com/myapp-2.5.0.tar.gz'}

# Check if version is wrong
[app1] TASK: Download application (debug)> task.args['url'] = 'https://releases.example.com/myapp-2.5.1.tar.gz'

[app1] TASK: Download application (debug)> redo
# Task retries with corrected URL
```

---

## 🔄 Redo and Continue

### Using redo Command

```yaml
---
- name: Redo Example
  hosts: localhost
  debugger: on_failed
  
  vars:
    retry_count: 0
  
  tasks:
    - name: Flaky network operation
      uri:
        url: https://api.example.com/data
        method: GET
      register: api_response
```

**Debug session:**

```
[localhost] TASK: Flaky network operation (debug)> p retry_count
0

[localhost] TASK: Flaky network operation (debug)> retry_count = retry_count + 1

[localhost] TASK: Flaky network operation (debug)> p retry_count
1

[localhost] TASK: Flaky network operation (debug)> redo
# Task runs again
```

### Using continue Command

```
[localhost] TASK: some_task (debug)> c
# Continues to next task
```

---

## 🐛 Debugging Strategies

### Strategy 1: Inspect Before Failure

```yaml
---
- name: Pre-Failure Inspection
  hosts: servers
  debugger: always  # Debug before failure
  
  tasks:
    - name: Complex task
      shell: |
        cd {{ app_dir }}
        ./deploy.sh {{ version }}
      # Enter debugger to inspect variables before execution
```

### Strategy 2: Conditional Debugging

```yaml
---
- name: Conditional Debug
  hosts: servers
  
  tasks:
    - name: Task that might fail
      command: "{{ risky_command }}"
      debugger: "{{ 'always' if debug_mode | default(false) else 'never' }}"
```

**Run with debugging:**

```bash
ansible-playbook playbook.yml -e "debug_mode=true"
```

### Strategy 3: Debug Specific Hosts

```yaml
---
- name: Debug Specific Host
  hosts: servers
  
  tasks:
    - name: Task to debug
      command: some_command
      debugger: "{{ 'always' if inventory_hostname == 'problem_server' else 'never' }}"
```

---

## 💡 Advanced Debugging Techniques

### Debugging with Registered Variables

```yaml
---
- name: Debug Registered Variables
  hosts: localhost
  debugger: always
  
  tasks:
    - name: Get system information
      command: uname -a
      register: system_info
    
    - name: Process system info
      debug:
        msg: "System: {{ system_info.stdout }}"
```

**Debug session:**

```
[localhost] TASK: Process system info (debug)> p system_info
{'changed': True,
 'cmd': ['uname', '-a'],
 'delta': '0:00:00.003421',
 'end': '2024-11-10 10:30:25.123456',
 'rc': 0,
 'start': '2024-11-10 10:30:25.120035',
 'stderr': '',
 'stdout': 'Linux web-01 5.4.0-42-generic #46-Ubuntu SMP x86_64 GNU/Linux'}

[localhost] TASK: Process system info (debug)> p system_info.stdout
'Linux web-01 5.4.0-42-generic #46-Ubuntu SMP x86_64 GNU/Linux'

[localhost] TASK: Process system info (debug)> p system_info.rc
0
```

### Debugging Loops

```yaml
---
- name: Debug Loops
  hosts: localhost
  debugger: always
  
  tasks:
    - name: Process multiple items
      debug:
        msg: "Processing {{ item }}"
      loop:
        - item1
        - item2
        - item3
```

**Debug session:**

```
[localhost] TASK: Process multiple items (debug)> p item
'item1'

[localhost] TASK: Process multiple items (debug)> c
# Moves to next iteration

[localhost] TASK: Process multiple items (debug)> p item
'item2'
```

### Debugging Conditionals

```yaml
---
- name: Debug Conditionals
  hosts: localhost
  debugger: always
  
  vars:
    deploy_to_production: false
  
  tasks:
    - name: Conditional deployment
      command: /opt/deploy.sh
      when: deploy_to_production
```

**Debug session:**

```
[localhost] TASK: Conditional deployment (debug)> p deploy_to_production
False

[localhost] TASK: Conditional deployment (debug)> p task.when
'deploy_to_production'

# Change condition to force execution
[localhost] TASK: Conditional deployment (debug)> deploy_to_production = True

[localhost] TASK: Conditional deployment (debug)> redo
```

---

## 🎯 Debugging Failed Tasks Pattern

```yaml
---
- name: Production Debugging Pattern
  hosts: production
  debugger: on_failed
  
  tasks:
    - name: Critical operation
      block:
        - name: Backup data
          command: /opt/backup.sh
          register: backup_result
        
        - name: Deploy new version
          command: /opt/deploy.sh {{ version }}
          register: deploy_result
        
        - name: Run health check
          uri:
            url: "http://localhost:8080/health"
            status_code: 200
          register: health_result
      
      rescue:
        - name: Rollback on failure
          command: /opt/rollback.sh
          debugger: always  # Debug rollback issues
```

**Debug session on failure:**

```
TASK [Run health check] ****************
fatal: [prod1]: FAILED! => {"status": 503}

[prod1] TASK: Run health check (debug)> p health_result
{'status': 503, 'msg': 'Service unavailable'}

[prod1] TASK: Run health check (debug)> p deploy_result
{'changed': True, 'rc': 0, 'stdout': 'Deployed version 2.0.0'}

# Check what went wrong
[prod1] TASK: Run health check (debug)> !curl -v http://localhost:8080/health

# Fix and retry
[prod1] TASK: Run health check (debug)> redo
```

---

## 💡 Best Practices

### 1. Use on_failed for Production

```yaml
# ✅ GOOD - Only debug failures
- name: Production playbook
  hosts: production
  debugger: on_failed
```

### 2. Combine with Check Mode

```bash
# Test with check mode first
ansible-playbook playbook.yml --check

# Then debug actual run
ANSIBLE_ENABLE_TASK_DEBUGGER=True ansible-playbook playbook.yml
```

### 3. Log Debug Sessions

```bash
# Capture debug session
ANSIBLE_ENABLE_TASK_DEBUGGER=True ansible-playbook playbook.yml | tee debug-session.log
```

### 4. Use Task-Level Debugging

```yaml
# ✅ GOOD - Debug specific complex tasks
- name: Complex task
  shell: |
    complex_script.sh
  debugger: on_failed  # Only this task

- name: Simple task
  debug:
    msg: "Normal execution"
  # No debugging
```

---

## 🔧 Debugging Common Issues

### Issue 1: Variable Not Defined

```yaml
- name: Debug undefined variable
  hosts: localhost
  debugger: on_failed
  
  tasks:
    - name: Use undefined variable
      debug:
        msg: "{{ undefined_var }}"
```

**Debug session:**

```
[localhost] TASK: Use undefined variable (debug)> p undefined_var
ERROR: variable 'undefined_var' is undefined

[localhost] TASK: Use undefined variable (debug)> undefined_var = 'default_value'

[localhost] TASK: Use undefined variable (debug)> redo
```

### Issue 2: Wrong File Path

```yaml
- name: Debug file path
  hosts: localhost
  debugger: on_failed
  
  tasks:
    - name: Read config file
      slurp:
        src: "{{ config_path }}"
```

**Debug session:**

```
[localhost] TASK: Read config file (debug)> p config_path
'/wrong/path/config.yml'

[localhost] TASK: Read config file (debug)> !ls /etc/myapp/
config.yml  settings.yml

[localhost] TASK: Read config file (debug)> task.args['src'] = '/etc/myapp/config.yml'

[localhost] TASK: Read config file (debug)> redo
```

### Issue 3: Permission Denied

```yaml
- name: Debug permissions
  hosts: localhost
  debugger: on_failed
  become: yes
  
  tasks:
    - name: Write to protected file
      copy:
        content: "data"
        dest: /etc/protected/file.txt
```

**Debug session:**

```
[localhost] TASK: Write to protected file (debug)> p ansible_become
False

# realize become didn't apply to this task
[localhost] TASK: Write to protected file (debug)> q
# Quit, fix playbook, and re-run
```

---

## 📝 Summary

**Key Takeaways:**

1. **Enable debugger** with `debugger: on_failed` for automatic debugging
2. Use **p** command to inspect variables
3. Use **task.args** to view and modify task parameters
4. Use **redo** to retry tasks after fixes
5. Use **continue** to proceed with execution
6. Debug at **play** or **task** level
7. Combine with **check mode** for safe testing

**Common Debugger Commands:**

- `p variable` - Print variable value
- `p task.args` - Show task arguments
- `p result` - Show task result
- `redo` - Retry current task
- `continue` - Continue execution
- `quit` - Exit debugger

**When to Use Debugger:**

- ✅ Troubleshooting production issues
- ✅ Understanding complex playbook logic
- ✅ Fixing intermittent failures
- ✅ Learning how tasks execute
- ✅ Debugging variable interpolation

**Next Steps:**

- Complete Lab 4: Interactive Debugging
- Practice debugging failed tasks
- Move on to Topic 5: Delegation & Rolling Updates

---

## 📖 Additional Resources

- [Official Docs: Debugging](https://docs.ansible.com/ansible/latest/user_guide/playbooks_debugger.html)
- [Troubleshooting Guide](https://docs.ansible.com/ansible/latest/user_guide/playbooks_startnstep.html)
- [Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)

---

**Ready for hands-on practice? Head to `labs/lab4-debugger.md`! 🚀**
