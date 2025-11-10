# Topic 2: Asynchronous Actions and Polling

## 📚 Overview

Asynchronous execution in Ansible allows you to run long-running tasks in the background without blocking the playbook execution. This is essential for operations like backups, large file transfers, system updates, or any task that takes significant time to complete.

### 🎯 Learning Objectives

By the end of this lesson, you will:

- ✅ Understand asynchronous task execution
- ✅ Implement fire-and-forget operations
- ✅ Use polling to monitor async tasks
- ✅ Run tasks in parallel across multiple hosts
- ✅ Handle timeout scenarios effectively
- ✅ Check status of asynchronous tasks

### ⏱️ Estimated Time

- Theory: 35 minutes
- Lab: 40 minutes
- Total: 75 minutes

---

## 🚀 Why Use Async?

### Common Use Cases

**Long-Running Operations:**
- Database backups (30+ minutes)
- Large file downloads
- System package updates
- Data migrations
- Batch processing

**Parallel Execution:**
- Deploy to multiple servers simultaneously
- Run independent tasks concurrently
- Reduce overall execution time

**Non-Blocking Operations:**
- Start services that take time to initialize
- Launch background processes
- Trigger external systems

---

## 🔧 Basic Async Syntax

### Simple Async Task

```yaml
---
- name: Basic async example
  hosts: servers
  
  tasks:
    - name: Long running task
      command: /opt/long_task.sh
      async: 300        # Maximum time to allow (seconds)
      poll: 0           # Don't wait for completion (fire-and-forget)
      register: long_task
```

**Key Parameters:**

- `async: N` - Maximum time (seconds) to allow for task completion
- `poll: N` - How often (seconds) to check task status
  - `poll: 0` = Fire-and-forget (don't wait)
  - `poll: 5` = Check every 5 seconds
  - Default = Check continuously until done

---

## 🎯 Pattern 1: Fire-and-Forget

Use when you don't need to wait for task completion.

```yaml
---
- name: Fire-and-forget pattern
  hosts: webservers
  
  tasks:
    - name: Start long-running backup (don't wait)
      shell: /usr/local/bin/backup.sh > /var/log/backup.log 2>&1
      async: 3600      # Allow up to 1 hour
      poll: 0          # Don't wait for completion
      register: backup_job
    
    - name: Continue with other tasks immediately
      debug:
        msg: "Backup started in background with job ID: {{ backup_job.ansible_job_id }}"
    
    - name: Do other work while backup runs
      apt:
        name: nginx
        state: present
```

**When to use:**
- Background processes
- Tasks you'll check later
- Non-critical operations

---

## 🔄 Pattern 2: Async with Polling

Use when you want to wait but check periodically.

```yaml
---
- name: Async with polling
  hosts: dbservers
  
  tasks:
    - name: Large database backup (poll every 30 seconds)
      postgresql_db:
        name: production_db
        state: dump
        target: /backup/prod_{{ ansible_date_time.date }}.sql
      async: 3600      # 1 hour timeout
      poll: 30         # Check every 30 seconds
      become: yes
      become_user: postgres
    
    - name: This runs after backup completes
      debug:
        msg: "Backup completed successfully!"
```

**Benefits:**
- Prevents SSH timeout on long tasks
- Shows progress periodically
- Allows Ansible to remain responsive

---

## 📊 Pattern 3: Check Status Later

Launch tasks and check status separately.

```yaml
---
- name: Launch and check later
  hosts: servers
  
  tasks:
    # Phase 1: Start tasks
    - name: Start backup on all servers
      command: /opt/backup.sh
      async: 3600
      poll: 0
      register: backup_jobs
    
    # Phase 2: Do other work
    - name: Update system packages
      apt:
        upgrade: dist
        update_cache: yes
    
    - name: Restart services
      systemd:
        name: "{{ item }}"
        state: restarted
      loop:
        - nginx
        - mysql
    
    # Phase 3: Check backup status
    - name: Check if backups completed
      async_status:
        jid: "{{ backup_jobs.ansible_job_id }}"
      register: backup_result
      until: backup_result.finished
      retries: 60
      delay: 30
    
    - name: Display backup results
      debug:
        msg: "Backup finished with return code: {{ backup_result.rc }}"
```

---

## 🔥 Pattern 4: Parallel Execution

Run tasks on multiple hosts simultaneously.

```yaml
---
- name: Parallel execution across hosts
  hosts: webservers
  strategy: free    # Don't wait for slowest host
  
  tasks:
    - name: Download large file on all servers simultaneously
      get_url:
        url: https://releases.example.com/app-v2.tar.gz
        dest: /tmp/app-v2.tar.gz
      async: 600
      poll: 10
    
    - name: Extract archive
      unarchive:
        src: /tmp/app-v2.tar.gz
        dest: /opt/app
        remote_src: yes
      async: 300
      poll: 5
```

**Strategy Options:**

- `strategy: linear` (default) - Wait for all hosts to complete each task
- `strategy: free` - Each host proceeds independently
- `strategy: debug` - Interactive debugging mode

---

## 💡 Real-World Example: System Updates

```yaml
---
- name: Update systems with async to prevent timeouts
  hosts: production
  serial: 1
  
  tasks:
    - name: Update all packages (can take 10-30 minutes)
      apt:
        upgrade: dist
        update_cache: yes
        autoremove: yes
        autoclean: yes
      async: 3600      # 1 hour timeout
      poll: 60         # Check every minute
      register: update_result
      become: yes
    
    - name: Display update summary
      debug:
        msg: |
          Updates completed on {{ inventory_hostname }}
          Packages updated: {{ update_result.stdout_lines | select('search', 'upgraded') | list }}
    
    - name: Check if reboot required
      stat:
        path: /var/run/reboot-required
      register: reboot_needed
    
    - name: Reboot if needed (async to handle SSH disconnect)
      reboot:
        reboot_timeout: 600
      async: 600
      poll: 0
      when: reboot_needed.stat.exists
      register: reboot_job
    
    - name: Wait for server to come back
      wait_for_connection:
        delay: 30
        timeout: 300
      when: reboot_needed.stat.exists
    
    - name: Verify system is up
      command: uptime
      when: reboot_needed.stat.exists
```

---

## 🏗️ Advanced Pattern: Multiple Async Tasks

Manage multiple async tasks efficiently.

```yaml
---
- name: Multiple async tasks with coordination
  hosts: appservers
  
  vars:
    services:
      - name: backup_database
        command: /opt/scripts/backup_db.sh
        timeout: 3600
      - name: optimize_images
        command: /opt/scripts/optimize_images.sh
        timeout: 1800
      - name: generate_reports
        command: /opt/scripts/generate_reports.sh
        timeout: 900
  
  tasks:
    # Start all tasks
    - name: Launch all background tasks
      command: "{{ item.command }}"
      async: "{{ item.timeout }}"
      poll: 0
      loop: "{{ services }}"
      register: async_jobs
    
    - name: Show launched jobs
      debug:
        msg: "Started {{ item.item.name }} with job ID {{ item.ansible_job_id }}"
      loop: "{{ async_jobs.results }}"
    
    # Do other work
    - name: Perform other tasks while background jobs run
      debug:
        msg: "Background tasks running, doing other work..."
    
    - name: Clean temporary files
      file:
        path: /tmp/*.tmp
        state: absent
    
    # Check all tasks
    - name: Wait for all background tasks to complete
      async_status:
        jid: "{{ item.ansible_job_id }}"
      register: job_results
      until: job_results.finished
      retries: 120
      delay: 30
      loop: "{{ async_jobs.results }}"
    
    - name: Display results of all tasks
      debug:
        msg: |
          Task: {{ item.item.item.name }}
          Status: {{ 'Success' if item.rc == 0 else 'Failed' }}
          Return Code: {{ item.rc }}
      loop: "{{ job_results.results }}"
```

---

## 📝 Real-World Scenario: Database Migration

```yaml
---
- name: Database migration with async monitoring
  hosts: dbservers
  become: yes
  
  vars:
    migration_timeout: 7200  # 2 hours
    check_interval: 60       # Check every minute
  
  tasks:
    - name: Pre-migration backup
      postgresql_db:
        name: production_db
        state: dump
        target: /backup/pre_migration_{{ ansible_date_time.epoch }}.sql
      become_user: postgres
      async: "{{ migration_timeout }}"
      poll: 30
    
    - name: Run migration (long-running)
      command: /opt/migrations/run_migration.sh
      async: "{{ migration_timeout }}"
      poll: 0
      register: migration_job
    
    - name: Monitor migration progress
      async_status:
        jid: "{{ migration_job.ansible_job_id }}"
      register: migration_status
      until: migration_status.finished
      retries: "{{ (migration_timeout / check_interval) | int }}"
      delay: "{{ check_interval }}"
      failed_when: migration_status.rc != 0
    
    - name: Show migration output
      debug:
        msg: |
          Migration completed!
          Duration: {{ migration_status.delta }}
          Output: {{ migration_status.stdout_lines[-10:] }}
    
    - name: Verify migration
      postgresql_query:
        db: production_db
        query: "SELECT version FROM schema_migrations ORDER BY applied_at DESC LIMIT 1"
      become_user: postgres
      register: current_version
    
    - name: Display current version
      debug:
        msg: "Database now at version: {{ current_version.query_result[0].version }}"
```

---

## ⚡ Performance Optimization

### Before: Sequential Execution (Slow)

```yaml
# This takes 30 minutes per server = 2.5 hours for 5 servers
- name: Sequential backup (slow)
  hosts: servers
  
  tasks:
    - name: Backup each server one by one
      command: /opt/backup.sh
      # Takes 30 minutes per server
```

### After: Parallel Async (Fast)

```yaml
# This takes 30 minutes total for all 5 servers
- name: Parallel backup (fast)
  hosts: servers
  strategy: free
  
  tasks:
    - name: Backup all servers simultaneously
      command: /opt/backup.sh
      async: 3600
      poll: 60
      # All servers backup at once
```

**Performance Gain:** 80% reduction in total time!

---

## 🚨 Error Handling with Async

```yaml
---
- name: Async with error handling
  hosts: servers
  
  tasks:
    - name: Start risky operation
      command: /opt/risky_operation.sh
      async: 1800
      poll: 0
      register: risky_job
      ignore_errors: yes
    
    - name: Do other work
      debug:
        msg: "Continuing with other tasks..."
    
    - name: Check operation status
      async_status:
        jid: "{{ risky_job.ansible_job_id }}"
      register: operation_status
      until: operation_status.finished
      retries: 30
      delay: 60
      ignore_errors: yes
    
    - name: Handle failure
      block:
        - name: Check if operation failed
          fail:
            msg: "Operation failed with return code {{ operation_status.rc }}"
          when: operation_status.rc != 0
      
      rescue:
        - name: Log error
          copy:
            content: |
              Operation failed at {{ ansible_date_time.iso8601 }}
              Error: {{ operation_status.stderr }}
            dest: /var/log/operation_failure.log
        
        - name: Run cleanup
          command: /opt/cleanup.sh
```

---

## 💡 Best Practices

### 1. Set Appropriate Timeouts

```yaml
# ❌ BAD - Timeout too short
- command: /opt/long_backup.sh
  async: 60      # Will timeout!
  poll: 5

# ✅ GOOD - Realistic timeout
- command: /opt/long_backup.sh
  async: 3600    # 1 hour
  poll: 30       # Check every 30 seconds
```

### 2. Use Meaningful Job IDs

```yaml
# ✅ GOOD - Save job ID for later
- name: Start backup
  command: /opt/backup.sh
  async: 3600
  poll: 0
  register: backup_job

- name: Save job ID for reference
  copy:
    content: "{{ backup_job.ansible_job_id }}"
    dest: /var/run/backup_job_id.txt
```

### 3. Monitor Critical Tasks

```yaml
# ✅ GOOD - Monitor important operations
- name: Critical database migration
  command: /opt/migrate.sh
  async: 7200
  poll: 60       # Check every minute, not fire-and-forget
  register: migration
```

### 4. Handle Timeouts Gracefully

```yaml
# ✅ GOOD - Timeout handling
- name: Operation with timeout handling
  command: /opt/operation.sh
  async: 1800
  poll: 30
  register: operation
  failed_when: false

- name: Check if timed out
  debug:
    msg: "Operation timed out!"
  when: operation.finished == 0
```

---

## 🔍 Debugging Async Tasks

### Check Job Status Manually

```yaml
- name: Launch task
  command: /opt/task.sh
  async: 3600
  poll: 0
  register: job

- name: Show job ID
  debug:
    msg: "Job ID: {{ job.ansible_job_id }}"

# Later, check status
- name: Check status manually
  async_status:
    jid: "{{ job.ansible_job_id }}"
  register: result

- name: Show detailed status
  debug:
    var: result
```

### Common Issues

**Issue 1: Task times out**
```yaml
# Solution: Increase async timeout
async: 7200  # Increase from 1800 to 7200
```

**Issue 2: Lost job ID**
```yaml
# Solution: Save job ID to file
- copy:
    content: "{{ job.ansible_job_id }}"
    dest: /tmp/job_id.txt
```

**Issue 3: Can't check status**
```yaml
# Solution: Use become if task was run with become
- async_status:
    jid: "{{ job.ansible_job_id }}"
  become: yes  # Match original task privileges
```

---

## 📊 Comparison Table

| Feature | Synchronous | Async (poll > 0) | Async (poll = 0) |
|---------|------------|------------------|------------------|
| Blocks playbook | ✅ Yes | ✅ Yes | ❌ No |
| Shows progress | ✅ Yes | ⚠️ Periodic | ❌ No |
| Can timeout | ❌ No | ✅ Yes | ✅ Yes |
| Parallel execution | ❌ No | ⚠️ Limited | ✅ Yes |
| Use for long tasks | ❌ No | ✅ Yes | ✅ Yes |
| Must check status | N/A | ❌ No | ✅ Yes |

---

## 📝 Summary

**Key Takeaways:**

1. **Async** prevents SSH timeouts on long-running tasks
2. **poll: 0** = Fire-and-forget (don't wait)
3. **poll: N** = Check every N seconds
4. Use **async_status** to check task status later
5. **strategy: free** enables true parallel execution
6. Always set realistic **timeout values**
7. Save **ansible_job_id** for later status checks

**When to Use Async:**
- Tasks taking > 10 minutes
- Operations across many hosts
- Background processes
- Large file transfers
- System updates
- Database operations

**Next Steps:**
- Complete Lab 2: Async Tasks and Polling
- Practice parallel execution patterns
- Move on to Topic 3: Check Mode

---

## 📖 Additional Resources

- [Official Docs: Async Actions](https://docs.ansible.com/ansible/latest/user_guide/playbooks_async.html)
- [Performance Tuning](https://docs.ansible.com/ansible/latest/user_guide/playbooks_strategies.html)
- [Async Status Module](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/async_status_module.html)

---

**Ready for hands-on practice? Head to `labs/lab2-async-tasks.md`! 🚀**
