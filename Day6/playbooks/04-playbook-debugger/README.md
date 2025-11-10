# Playbook Debugger Examples

This directory contains practical examples demonstrating Ansible's interactive debugger for troubleshooting and debugging playbooks.

## 📁 Files

1. **inventory.ini** - Sample inventory for testing
2. **basic-debugger.yml** - Simple debugger activation on failures
3. **variable-inspection.yml** - Inspecting and modifying variables
4. **task-modification.yml** - Changing task arguments in debugger
5. **conditional-debugging.yml** - Selective debugging based on conditions
6. **production-debugging.yml** - Production-safe debugging patterns

## 🚀 Quick Start

### Prerequisites

- Ansible 2.9+
- SSH access to target hosts (or use localhost)

### Basic Usage

```bash
# Run playbook with debugger enabled
ANSIBLE_ENABLE_TASK_DEBUGGER=True ansible-playbook -i inventory.ini basic-debugger.yml

# Or set in environment
export ANSIBLE_ENABLE_TASK_DEBUGGER=True
ansible-playbook -i inventory.ini basic-debugger.yml
```

## 📚 Debugger Commands Reference

| Command | Shortcut | Description |
|---------|----------|-------------|
| print | p | Print variable value |
| task | t | Display current task |
| task.args | t.args | Show task arguments |
| vars | v | Show all variables |
| result | r | Show task result |
| continue | c | Continue execution |
| quit | q | Quit debugger (fail task) |
| redo | rd | Run task again |
| update_task | u | Modify task arguments |

## 🎯 Example Workflows

### 1. Basic Debugging

```bash
# Run playbook that will fail
ansible-playbook -i inventory.ini basic-debugger.yml
```

When debugger activates:
```
[localhost] TASK: Task name (debug)> p variable_name
[localhost] TASK: Task name (debug)> p task.args
[localhost] TASK: Task name (debug)> redo
[localhost] TASK: Task name (debug)> c
```

### 2. Variable Inspection

```bash
ansible-playbook -i inventory.ini variable-inspection.yml
```

Debug session:
```
[localhost] TASK: Task name (debug)> p app_name
[localhost] TASK: Task name (debug)> p database
[localhost] TASK: Task name (debug)> p database['host']
```

### 3. Task Modification

```bash
ansible-playbook -i inventory.ini task-modification.yml
```

Fix task arguments:
```
[localhost] TASK: Task name (debug)> p task.args
[localhost] TASK: Task name (debug)> task.args['src'] = '/correct/path'
[localhost] TASK: Task name (debug)> redo
```

### 4. Conditional Debugging

```bash
# Debug only when flag is set
ansible-playbook -i inventory.ini conditional-debugging.yml -e "debug_mode=true"

# Debug only specific host
ansible-playbook -i inventory.ini conditional-debugging.yml -e "debug_host=web1"
```

### 5. Production Debugging

```bash
# Safe production debugging
ansible-playbook -i inventory.ini production-debugging.yml -e "environment=production"
```

## 💡 Common Debug Scenarios

### Scenario 1: File Not Found

```yaml
- name: Copy file
  copy:
    src: /wrong/path/file.txt
    dest: /tmp/file.txt
```

Debug:
```
[localhost] TASK: Copy file (debug)> p task.args['src']
'/wrong/path/file.txt'
[localhost] TASK: Copy file (debug)> task.args['src'] = '/correct/path/file.txt'
[localhost] TASK: Copy file (debug)> redo
```

### Scenario 2: Undefined Variable

```yaml
- name: Use variable
  debug:
    msg: "{{ undefined_var }}"
```

Debug:
```
[localhost] TASK: Use variable (debug)> undefined_var = 'default_value'
[localhost] TASK: Use variable (debug)> redo
```

### Scenario 3: Wrong Variable Value

```yaml
- name: Deploy app
  command: deploy.sh {{ app_version }}
```

Debug:
```
[localhost] TASK: Deploy app (debug)> p app_version
'1.0.0'
[localhost] TASK: Deploy app (debug)> app_version = '2.0.0'
[localhost] TASK: Deploy app (debug)> redo
```

## 🔧 Debugger Activation Modes

### on_failed (Recommended for Production)

```yaml
- hosts: servers
  debugger: on_failed  # Only debug failures
```

### always (For Development/Learning)

```yaml
- hosts: servers
  debugger: always  # Debug every task
```

### Task-Level Debugging

```yaml
- name: Complex task
  command: /opt/script.sh
  debugger: on_failed  # Only this task

- name: Normal task
  debug:
    msg: "No debugging"
```

### Conditional Debugging

```yaml
- name: Task
  command: echo "test"
  debugger: "{{ 'always' if debug_mode else 'never' }}"
```

## 🎓 Best Practices

### 1. Use on_failed in Production

```yaml
# ✅ GOOD
- hosts: production
  debugger: on_failed
```

### 2. Debug Specific Tasks

```yaml
# ✅ GOOD - Only debug complex tasks
- name: Complex deployment
  script: deploy.sh
  debugger: on_failed

- name: Simple task
  debug:
    msg: "Normal"
```

### 3. Combine with Check Mode

```bash
# Test first
ansible-playbook playbook.yml --check

# Then debug
ANSIBLE_ENABLE_TASK_DEBUGGER=True ansible-playbook playbook.yml
```

### 4. Log Debug Sessions

```bash
# Capture debug session output
ANSIBLE_ENABLE_TASK_DEBUGGER=True ansible-playbook playbook.yml | tee debug-log.txt
```

### 5. Use Conditional Debugging

```yaml
# ✅ GOOD - Debug only when needed
- hosts: servers
  vars:
    enable_debug: false  # Set via -e flag
  
  tasks:
    - name: Task
      command: echo "test"
      debugger: "{{ 'always' if enable_debug else 'on_failed' }}"
```

## 🐛 Troubleshooting

### Problem: Debugger Not Activating

**Solution 1:** Enable via environment
```bash
export ANSIBLE_ENABLE_TASK_DEBUGGER=True
```

**Solution 2:** Enable in playbook
```yaml
- hosts: servers
  debugger: on_failed
```

**Solution 3:** Check ansible.cfg
```ini
[defaults]
enable_task_debugger = True
```

### Problem: Can't See Variables

**Solution:** Use print command
```
[host] TASK: task (debug)> p vars
[host] TASK: task (debug)> p hostvars[inventory_hostname]
```

### Problem: Task Still Fails After redo

**Solution:** Check task arguments
```
[host] TASK: task (debug)> p task.args
[host] TASK: task (debug)> p result
```

## 📖 Related Resources

- Day 6 Lesson: `../04-playbook-debugger.md`
- Lab: `../../labs/lab4-debugger.md`
- [Official Documentation](https://docs.ansible.com/ansible/latest/user_guide/playbooks_debugger.html)

## 🎯 Learning Objectives

After working with these examples, you should understand:

- ✅ How to enable and use the Ansible debugger
- ✅ How to inspect variables and task state
- ✅ How to modify task arguments interactively
- ✅ How to use debugger commands effectively
- ✅ When to use different debugger modes
- ✅ How to implement production-safe debugging

## 🚀 Next Steps

1. Run each example playbook
2. Practice debugger commands
3. Complete Lab 4 exercises
4. Try debugging your own playbooks
5. Move on to Topic 5: Delegation & Rolling Updates
