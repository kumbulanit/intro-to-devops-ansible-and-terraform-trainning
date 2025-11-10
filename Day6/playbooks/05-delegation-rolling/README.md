# Delegation and Rolling Updates Examples

This directory contains practical examples demonstrating task delegation, run_once patterns, and rolling update strategies for zero-downtime deployments.

## 📁 Files

1. **inventory.ini** - Sample multi-tier inventory
2. **basic-delegation.yml** - Task delegation examples
3. **run-once-pattern.yml** - Single execution across multiple hosts
4. **rolling-update.yml** - Basic rolling update with serial
5. **canary-deployment.yml** - Staged deployment (canary → early adopter → GA)
6. **zero-downtime-deployment.yml** - Complete zero-downtime pattern

## 🚀 Quick Start

### Prerequisites

- Ansible 2.9+
- Multiple hosts (or use localhost simulation)

### Basic Usage

```bash
# Simple delegation
ansible-playbook -i inventory.ini basic-delegation.yml

# Run once pattern
ansible-playbook -i inventory.ini run-once-pattern.yml

# Rolling update
ansible-playbook -i inventory.ini rolling-update.yml

# Canary deployment
ansible-playbook -i inventory.ini canary-deployment.yml

# Zero-downtime deployment
ansible-playbook -i inventory.ini zero-downtime-deployment.yml
```

## 🎯 Key Concepts

### Task Delegation

Run tasks on different hosts than the play targets:

```yaml
- name: Task on remote host
  command: some_command
  delegate_to: another_host
```

### Run Once

Execute task once across all hosts:

```yaml
- name: Shared operation
  command: create_shared_resource
  run_once: true
```

### Serial Execution

Update hosts in batches:

```yaml
- hosts: webservers
  serial: 2  # or "25%" for percentage
  tasks:
    - name: Rolling update
      ...
```

### Staged Rollout

Multiple batch sizes for risk mitigation:

```yaml
- hosts: servers
  serial:
    - 1      # Canary
    - 25%    # Early adopters
    - 100%   # Everyone else
```

## 💡 Common Patterns

### Pattern 1: Load Balancer Management

```yaml
- name: Remove from LB
  command: lb-remove {{ inventory_hostname }}
  delegate_to: loadbalancer

- name: Update application
  copy:
    src: app.jar
    dest: /opt/app/

- name: Add to LB
  command: lb-add {{ inventory_hostname }}
  delegate_to: loadbalancer
```

### Pattern 2: Database Orchestration

```yaml
- name: Update primary
  mysql_db:
    name: appdb
    state: import
    target: migration.sql
  when: inventory_hostname == groups['databases'][0]
  run_once: true
```

### Pattern 3: Monitoring Integration

```yaml
- name: Notify monitoring
  uri:
    url: "http://monitoring/api/deploy"
    method: POST
    body:
      host: "{{ inventory_hostname }}"
      status: "deploying"
  delegate_to: localhost
```

## 🎯 Example Workflows

### Workflow 1: Basic Delegation

```bash
ansible-playbook -i inventory.ini basic-delegation.yml
```

**What it does:**
- Executes tasks on different hosts
- Logs operations to control machine
- Demonstrates delegate_to patterns

### Workflow 2: Run Once Notification

```bash
ansible-playbook -i inventory.ini run-once-pattern.yml
```

**What it does:**
- Creates shared resources once
- Sends single notification for all hosts
- Shows run_once with delegation

### Workflow 3: Rolling Update (50% batches)

```bash
ansible-playbook -i inventory.ini rolling-update.yml
```

**What it does:**
- Updates servers in batches
- Maintains service availability
- Validates each batch before proceeding

### Workflow 4: Canary Deployment

```bash
ansible-playbook -i inventory.ini canary-deployment.yml
```

**What it does:**
- Deploys to 1 canary server first
- Then 25% of remaining servers
- Finally deploys to all remaining
- Monitors each stage for issues

### Workflow 5: Zero-Downtime Deployment

```bash
ansible-playbook -i inventory.ini zero-downtime-deployment.yml
```

**What it does:**
- Removes server from load balancer
- Drains connections
- Updates application
- Health checks
- Re-adds to load balancer
- One server at a time (serial: 1)

## 🔧 Configuration Options

### Serial Strategies

```yaml
# Fixed number
serial: 2

# Percentage
serial: "25%"

# Multiple stages
serial:
  - 1
  - 25%
  - 100%

# Complex staging
serial:
  - 1           # Canary
  - "10%"       # Early
  - "50%"       # Most
  - 100%        # All remaining
```

### Failure Handling

```yaml
# Allow some failures
max_fail_percentage: 20

# Stop everything on any failure
any_errors_fatal: true

# Ignore errors
ignore_errors: yes
```

### Delegation Options

```yaml
# Delegate to specific host
delegate_to: monitoring.example.com

# Delegate to localhost
delegate_to: localhost

# Delegate to variable
delegate_to: "{{ monitoring_server }}"

# Delegate with facts
delegate_facts: true
```

## 🎓 Best Practices

### 1. Always Use Serial for Production

```yaml
# ✅ GOOD
- hosts: production
  serial: "25%"
  max_fail_percentage: 10
```

### 2. Validate After Each Batch

```yaml
# ✅ GOOD
- name: Health check
  uri:
    url: "http://{{ inventory_hostname }}/health"
    status_code: 200
  retries: 10
  delay: 6
```

### 3. Implement Rollback

```yaml
# ✅ GOOD
rescue:
  - name: Rollback
    copy:
      src: /backup/app.jar
      dest: /opt/app/app.jar
```

### 4. Use run_once for Shared Operations

```yaml
# ✅ GOOD
- name: Send notification
  mail:
    to: team@example.com
    subject: "Deployment started"
  run_once: true
  delegate_to: localhost
```

### 5. Wait Between Batches

```yaml
# ✅ GOOD
- name: Stability wait
  pause:
    seconds: 30
  when: inventory_hostname == ansible_play_batch[-1]
```

## 🐛 Troubleshooting

### Issue: Tasks Running on Wrong Host

**Solution:** Check delegate_to
```yaml
- name: Task
  command: some_command
  delegate_to: correct_host  # Make sure this is right
```

### Issue: Run Once Executing Multiple Times

**Solution:** Ensure run_once is at task level
```yaml
- name: Task
  command: some_command
  run_once: true  # Must be on the task
```

### Issue: Serial Not Working

**Solution:** Check serial is at play level
```yaml
- hosts: servers
  serial: 2  # Must be at play level, not task level
  tasks:
    ...
```

### Issue: All Servers Fail When One Fails

**Solution:** Adjust max_fail_percentage
```yaml
- hosts: servers
  serial: 5
  max_fail_percentage: 20  # Allow 20% to fail
```

## 📖 Related Resources

- Day 6 Lesson: `../05-delegation-rolling-updates.md`
- Lab: `../../labs/lab5-rolling-updates.md`
- [Delegation Docs](https://docs.ansible.com/ansible/latest/user_guide/playbooks_delegation.html)
- [Strategies Docs](https://docs.ansible.com/ansible/latest/user_guide/playbooks_strategies.html)

## 🎯 Learning Objectives

After working with these examples, you should understand:

- ✅ How to delegate tasks to different hosts
- ✅ When to use run_once pattern
- ✅ How to implement rolling updates
- ✅ How to perform canary deployments
- ✅ How to achieve zero-downtime deployments
- ✅ How to handle failures gracefully

## 🚀 Next Steps

1. Run each example playbook
2. Modify serial values to see different batch sizes
3. Complete Lab 5 exercises
4. Implement rolling updates in your own playbooks
5. Move on to Topic 6: Environment & Proxies
