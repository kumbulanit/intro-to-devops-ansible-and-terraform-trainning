# Lab 2: Asynchronous Actions and Polling

## 🎯 Lab Objectives

In this lab, you will:

- Execute long-running tasks asynchronously
- Implement fire-and-forget operations
- Monitor async tasks with polling
- Run tasks in parallel across multiple hosts
- Check status of background jobs
- Handle timeouts and errors in async operations

## ⏱️ Estimated Time

75 minutes

## 📋 Prerequisites

- Completed Day 1-5 lessons and Lab 1
- Access to your OpenStack instance or test servers
- Ansible 2.9 or higher installed
- Multiple test servers (or can test on localhost)

## 🏗️ Lab Environment Setup

### Option 1: Using Your OpenStack Instance

```bash
# SSH into your OpenStack instance
ssh -i ~/.ssh/openstack_key ubuntu@<your-instance-ip>

# Install required packages
sudo apt update
sudo apt install -y curl wget rsync
```

### Option 2: Using Local Machine

```bash
# Create lab directory
mkdir -p ~/ansible-labs/day6-lab2/{playbooks,inventory,scripts}
cd ~/ansible-labs/day6-lab2
```

### Create Test Scripts

```bash
# Create a long-running script
cat > scripts/long_task.sh <<'EOF'
#!/bin/bash
# Simulates a long-running task
DURATION=${1:-60}
echo "Starting task at $(date)"
echo "Will run for $DURATION seconds"

for i in $(seq 1 $DURATION); do
    echo "Progress: $i/$DURATION seconds"
    sleep 1
done

echo "Task completed at $(date)"
exit 0
EOF

chmod +x scripts/long_task.sh

# Create a backup simulation script
cat > scripts/backup_simulation.sh <<'EOF'
#!/bin/bash
echo "Starting backup at $(date)"
BACKUP_DIR="/tmp/backup_$(date +%s)"
mkdir -p "$BACKUP_DIR"

# Simulate backing up files
echo "Phase 1: Scanning files..."
sleep 10

echo "Phase 2: Copying files..."
for i in {1..20}; do
    echo "  Copying file $i of 20..."
    dd if=/dev/zero of="$BACKUP_DIR/file_$i.dat" bs=1M count=10 2>/dev/null
    sleep 2
done

echo "Phase 3: Compressing backup..."
tar -czf "$BACKUP_DIR.tar.gz" -C /tmp "$(basename $BACKUP_DIR)" 2>/dev/null
rm -rf "$BACKUP_DIR"

echo "Backup completed: $BACKUP_DIR.tar.gz"
echo "Backup size: $(du -h $BACKUP_DIR.tar.gz | cut -f1)"
exit 0
EOF

chmod +x scripts/backup_simulation.sh

# Create a download simulation script
cat > scripts/download_simulation.sh <<'EOF'
#!/bin/bash
URL=${1:-"https://releases.ubuntu.com/20.04/ubuntu-20.04.6-live-server-amd64.iso"}
DEST="/tmp/download_$(date +%s).iso"

echo "Starting download at $(date)"
echo "URL: $URL"
echo "Destination: $DEST"

# Use wget with progress
wget -O "$DEST" "$URL" 2>&1

if [ $? -eq 0 ]; then
    echo "Download completed successfully"
    echo "File size: $(du -h $DEST | cut -f1)"
    exit 0
else
    echo "Download failed"
    exit 1
fi
EOF

chmod +x scripts/download_simulation.sh
```

### Create Inventory

```bash
cat > inventory/hosts.ini <<EOF
[local]
localhost ansible_connection=local

[servers]
server1 ansible_host=localhost ansible_connection=local

# For OpenStack instance
[openstack]
# web1 ansible_host=<your-instance-ip> ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/openstack_key

[all:vars]
ansible_python_interpreter=/usr/bin/python3
EOF
```

---

## 📝 Exercise 1: Basic Fire-and-Forget

### Step 1: Create Simple Async Playbook

Create `playbooks/01-fire-and-forget.yml`:

```yaml
---
- name: Fire-and-Forget Pattern
  hosts: local
  gather_facts: yes
  
  tasks:
    - name: Copy long task script
      copy:
        src: ../scripts/long_task.sh
        dest: /tmp/long_task.sh
        mode: '0755'
    
    - name: Start long task (don't wait)
      command: /tmp/long_task.sh 30
      async: 60        # Max 60 seconds
      poll: 0          # Don't wait
      register: long_task_job
    
    - name: Show job ID
      debug:
        msg: |
          Task started in background!
          Job ID: {{ long_task_job.ansible_job_id }}
          Started at: {{ ansible_date_time.time }}
    
    - name: Continue immediately with other work
      debug:
        msg: "The long task is running in the background while we do other things"
    
    - name: Do some quick work
      command: echo "Quick task {{ item }}"
      loop: [1, 2, 3, 4, 5]
      register: quick_tasks
    
    - name: Save job ID for later
      copy:
        content: "{{ long_task_job.ansible_job_id }}"
        dest: /tmp/job_id.txt
    
    - name: Playbook continues without waiting
      debug:
        msg: "Playbook completed! Long task still running in background."
```

### Step 2: Run the Playbook

```bash
ansible-playbook -i inventory/hosts.ini playbooks/01-fire-and-forget.yml
```

**Expected Output:**

```
TASK [Start long task (don't wait)] ************
changed: [localhost]

TASK [Show job ID] *****************************
ok: [localhost] => {
    "msg": "Task started in background!\nJob ID: 123456.78901\nStarted at: 14:30:25"
}

TASK [Continue immediately with other work] ****
ok: [localhost] => {
    "msg": "The long task is running in the background while we do other things"
}

PLAY RECAP *************************************
localhost : ok=6    changed=2
```

### Step 3: Check Job Status Manually

Create `playbooks/02-check-status.yml`:

```yaml
---
- name: Check Background Job Status
  hosts: local
  gather_facts: no
  
  tasks:
    - name: Read saved job ID
      slurp:
        src: /tmp/job_id.txt
      register: job_id_file
    
    - name: Set job ID variable
      set_fact:
        saved_job_id: "{{ job_id_file.content | b64decode | trim }}"
    
    - name: Check job status
      async_status:
        jid: "{{ saved_job_id }}"
      register: job_status
      ignore_errors: yes
    
    - name: Display job status
      debug:
        msg: |
          Job ID: {{ saved_job_id }}
          Finished: {{ job_status.finished }}
          {% if job_status.finished == 1 %}
          Return Code: {{ job_status.rc }}
          Output:
          {{ job_status.stdout }}
          {% else %}
          Status: Still running...
          {% endif %}
```

Run immediately after the first playbook:

```bash
# Check status right away
ansible-playbook -i inventory/hosts.ini playbooks/02-check-status.yml

# Wait 30 seconds and check again
sleep 30
ansible-playbook -i inventory/hosts.ini playbooks/02-check-status.yml
```

---

## 📝 Exercise 2: Async with Polling

### Step 1: Create Polling Playbook

Create `playbooks/03-async-with-polling.yml`:

```yaml
---
- name: Async with Polling
  hosts: local
  gather_facts: yes
  
  tasks:
    - name: Copy backup script
      copy:
        src: ../scripts/backup_simulation.sh
        dest: /tmp/backup_simulation.sh
        mode: '0755'
    
    - name: Run backup with polling
      command: /tmp/backup_simulation.sh
      async: 300       # 5 minute timeout
      poll: 10         # Check every 10 seconds
      register: backup_result
    
    - name: Display backup results
      debug:
        msg: |
          Backup completed!
          Duration: {{ backup_result.delta }}
          Output:
          {{ backup_result.stdout_lines[-5:] }}
    
    - name: Verify backup file exists
      shell: ls -lh /tmp/backup_*.tar.gz | tail -1
      register: backup_file
      changed_when: false
    
    - name: Show backup file info
      debug:
        msg: "{{ backup_file.stdout }}"
```

### Step 2: Run with Polling

```bash
ansible-playbook -i inventory/hosts.ini playbooks/03-async-with-polling.yml -v
```

**Expected Output:**

```
TASK [Run backup with polling] *****************
ASYNC POLL on localhost: jid=123456.78901 started=1 finished=0
ASYNC POLL on localhost: jid=123456.78901 started=1 finished=0
ASYNC POLL on localhost: jid=123456.78901 started=1 finished=0
ASYNC OK on localhost: jid=123456.78901
changed: [localhost]

TASK [Display backup results] ******************
ok: [localhost] => {
    "msg": "Backup completed!\nDuration: 0:00:45\nOutput:\n  Copying file 18 of 20...\n..."
}
```

**📊 Observation:**
- Playbook checks status every 10 seconds
- Shows "ASYNC POLL" messages
- Waits for completion before continuing

---

## 📝 Exercise 3: Multiple Parallel Tasks

### Step 1: Create Parallel Execution Playbook

Create `playbooks/04-parallel-execution.yml`:

```yaml
---
- name: Parallel Task Execution
  hosts: local
  gather_facts: yes
  strategy: free    # Each host proceeds independently
  
  vars:
    tasks_to_run:
      - name: "task_a"
        duration: 30
      - name: "task_b"
        duration: 45
      - name: "task_c"
        duration: 20
  
  tasks:
    - name: Ensure script is present
      copy:
        src: ../scripts/long_task.sh
        dest: /tmp/long_task.sh
        mode: '0755'
    
    - name: Launch all tasks in parallel
      command: /tmp/long_task.sh {{ item.duration }}
      async: 120
      poll: 0
      loop: "{{ tasks_to_run }}"
      register: parallel_jobs
    
    - name: Show launched jobs
      debug:
        msg: |
          Launched {{ item.item.name }}:
          - Duration: {{ item.item.duration }} seconds
          - Job ID: {{ item.ansible_job_id }}
      loop: "{{ parallel_jobs.results }}"
    
    - name: Do other work while tasks run
      debug:
        msg: "All tasks running in parallel, doing other work..."
    
    - name: Wait for all tasks to complete
      async_status:
        jid: "{{ item.ansible_job_id }}"
      register: job_results
      until: job_results.finished
      retries: 24
      delay: 5
      loop: "{{ parallel_jobs.results }}"
    
    - name: Display results
      debug:
        msg: |
          Task: {{ item.item.item.name }}
          Duration: {{ item.item.item.duration }}s
          Return Code: {{ item.rc }}
          Actual Runtime: {{ item.delta }}
      loop: "{{ job_results.results }}"
```

### Step 2: Run Parallel Execution

```bash
time ansible-playbook -i inventory/hosts.ini playbooks/04-parallel-execution.yml
```

**Expected Output:**

```
TASK [Launch all tasks in parallel] ************
changed: [localhost] => (item={'name': 'task_a', 'duration': 30})
changed: [localhost] => (item={'name': 'task_b', 'duration': 45})
changed: [localhost] => (item={'name': 'task_c', 'duration': 20})

TASK [Show launched jobs] **********************
ok: [localhost] => (item=...) => {
    "msg": "Launched task_a:\n- Duration: 30 seconds\n- Job ID: 123.456"
}

TASK [Wait for all tasks to complete] **********
ASYNC POLL on localhost: jid=123.456 started=1 finished=0
...
ASYNC OK on localhost: jid=123.456

TASK [Display results] *************************
ok: [localhost] => (item=...) => {
    "msg": "Task: task_a\nDuration: 30s\nReturn Code: 0\nActual Runtime: 0:00:30"
}

real    0m50.123s  # Total time ≈ longest task (45s) + overhead
```

**📊 Analysis:**
- Total time ≈ longest task duration (not sum of all)
- All tasks ran simultaneously
- Significant time savings vs sequential execution

---

## 📝 Exercise 4: Real-World Backup Scenario

### Step 1: Create Multi-Server Backup Playbook

Create `playbooks/05-backup-multiple-servers.yml`:

```yaml
---
- name: Backup Multiple Servers Simultaneously
  hosts: servers
  become: yes
  gather_facts: yes
  strategy: free
  
  vars:
    backup_dir: /var/backups
    retention_days: 7
    timestamp: "{{ ansible_date_time.epoch }}"
  
  tasks:
    # Phase 1: Start backups on all servers
    - name: Ensure backup directory exists
      file:
        path: "{{ backup_dir }}"
        state: directory
        mode: '0755'
    
    - name: Start backup process (async)
      shell: |
        set -e
        echo "Starting backup on {{ inventory_hostname }}"
        
        # Backup system files
        tar -czf {{ backup_dir }}/system_{{ timestamp }}.tar.gz \
          /etc /var/log 2>/dev/null || true
        
        # Backup home directories
        tar -czf {{ backup_dir }}/home_{{ timestamp }}.tar.gz \
          /home 2>/dev/null || true
        
        echo "Backup completed on {{ inventory_hostname }}"
        ls -lh {{ backup_dir }}/*{{ timestamp }}*
      async: 600       # 10 minute timeout
      poll: 0          # Don't wait
      register: backup_jobs
    
    - name: Record backup start time
      copy:
        content: |
          Backup started: {{ ansible_date_time.iso8601 }}
          Host: {{ inventory_hostname }}
          Job ID: {{ backup_jobs.ansible_job_id }}
        dest: "{{ backup_dir }}/backup_{{ timestamp }}.log"
    
    # Phase 2: Do other maintenance while backups run
    - name: Clean old log files while backup runs
      shell: find /var/log -name "*.log" -type f -mtime +30 -delete
      changed_when: false
    
    - name: Update package cache
      apt:
        update_cache: yes
        cache_valid_time: 3600
      when: ansible_os_family == "Debian"
    
    # Phase 3: Wait for backups to complete
    - name: Wait for backup to complete
      async_status:
        jid: "{{ backup_jobs.ansible_job_id }}"
      register: backup_status
      until: backup_status.finished
      retries: 60
      delay: 10
    
    - name: Display backup results
      debug:
        msg: |
          Host: {{ inventory_hostname }}
          Backup Status: {{ 'Success' if backup_status.rc == 0 else 'Failed' }}
          Duration: {{ backup_status.delta }}
          Files created:
          {{ backup_status.stdout_lines[-3:] }}
    
    # Phase 4: Cleanup old backups
    - name: Find old backup files
      find:
        paths: "{{ backup_dir }}"
        patterns: "*.tar.gz"
        age: "{{ retention_days }}d"
      register: old_backups
    
    - name: Remove old backups
      file:
        path: "{{ item.path }}"
        state: absent
      loop: "{{ old_backups.files }}"
      when: old_backups.files | length > 0
    
    - name: Count remaining backups
      find:
        paths: "{{ backup_dir }}"
        patterns: "*.tar.gz"
      register: total_backups
    
    - name: Backup summary
      debug:
        msg: |
          Backup Summary for {{ inventory_hostname }}
          =========================================
          Status: Complete
          Old backups removed: {{ old_backups.files | length }}
          Total backups: {{ total_backups.files | length }}
          Backup location: {{ backup_dir }}

# Summary play
- name: Backup Summary
  hosts: servers
  gather_facts: no
  run_once: yes
  
  tasks:
    - name: Overall backup summary
      debug:
        msg: |
          ================================================
          All Server Backups Completed
          ================================================
          Total servers: {{ groups['servers'] | length }}
          All backups completed successfully!
```

### Step 2: Run Multi-Server Backup

```bash
ansible-playbook -i inventory/hosts.ini playbooks/05-backup-multiple-servers.yml
```

---

## 📝 Exercise 5: Handling Timeouts and Errors

### Step 1: Create Timeout Handling Playbook

Create `playbooks/06-timeout-handling.yml`:

```yaml
---
- name: Async Timeout and Error Handling
  hosts: local
  gather_facts: yes
  
  tasks:
    # Test 1: Task that will timeout
    - name: Task with insufficient timeout
      block:
        - name: Start task with short timeout
          command: sleep 60
          async: 20        # Too short!
          poll: 5
          register: timeout_task
          failed_when: false
      
      rescue:
        - name: Handle timeout
          debug:
            msg: |
              ⚠️  Task timed out as expected
              This demonstrates timeout handling
    
    # Test 2: Task that will fail
    - name: Task that will fail
      block:
        - name: Start failing task
          command: /bin/false
          async: 30
          poll: 5
          register: failed_task
      
      rescue:
        - name: Handle task failure
          debug:
            msg: |
              ⚠️  Task failed as expected
              Return code: {{ failed_task.rc | default('N/A') }}
    
    # Test 3: Proper timeout handling
    - name: Properly handle long-running task
      block:
        - name: Copy script
          copy:
            src: ../scripts/long_task.sh
            dest: /tmp/long_task.sh
            mode: '0755'
        
        - name: Start long task with appropriate timeout
          command: /tmp/long_task.sh 45
          async: 120       # Plenty of time
          poll: 0
          register: long_job
        
        - name: Monitor with timeout protection
          async_status:
            jid: "{{ long_job.ansible_job_id }}"
          register: job_status
          until: job_status.finished
          retries: 25
          delay: 5
          failed_when: false
        
        - name: Check if task timed out
          debug:
            msg: |
              {% if job_status.finished == 1 %}
              ✅ Task completed successfully
              Return Code: {{ job_status.rc }}
              Duration: {{ job_status.delta }}
              {% else %}
              ⚠️  Task timed out or didn't finish
              {% endif %}
        
        - name: Handle timeout scenario
          debug:
            msg: "Task didn't complete in expected time. Taking corrective action..."
          when: job_status.finished == 0
      
      always:
        - name: Cleanup
          debug:
            msg: "Cleanup runs regardless of success/failure"
```

### Step 2: Run Timeout Tests

```bash
ansible-playbook -i inventory/hosts.ini playbooks/06-timeout-handling.yml
```

---

## 📝 Exercise 6: Async Status Monitoring Dashboard

### Step 1: Create Monitoring Playbook

Create `playbooks/07-async-monitoring.yml`:

```yaml
---
- name: Async Task Monitoring Dashboard
  hosts: local
  gather_facts: yes
  
  vars:
    monitor_interval: 5
    max_monitoring_time: 120
  
  tasks:
    - name: Copy test script
      copy:
        src: ../scripts/long_task.sh
        dest: /tmp/long_task.sh
        mode: '0755'
    
    - name: Launch multiple test tasks
      command: /tmp/long_task.sh {{ item.duration }}
      async: 200
      poll: 0
      loop:
        - { name: "Quick Task", duration: 15 }
        - { name: "Medium Task", duration: 30 }
        - { name: "Long Task", duration: 45 }
      register: monitored_jobs
    
    - name: Create monitoring loop
      include_tasks: monitor_jobs.yml
      vars:
        jobs_to_monitor: "{{ monitored_jobs.results }}"

# Create monitor_jobs.yml as separate file
- name: Monitor job status
  hosts: local
  gather_facts: no
  
  tasks:
    - name: Check status of all jobs
      async_status:
        jid: "{{ item.ansible_job_id }}"
      loop: "{{ monitored_jobs.results }}"
      register: current_status
      ignore_errors: yes
    
    - name: Display status dashboard
      debug:
        msg: |
          ================================================
          Async Task Monitoring Dashboard
          ================================================
          Time: {{ ansible_date_time.time }}
          
          {% for job in current_status.results %}
          Task {{ loop.index }}:
            Job ID: {{ job.item.ansible_job_id }}
            Status: {{ 'Complete' if job.finished == 1 else 'Running' }}
            {% if job.finished == 1 %}
            Return Code: {{ job.rc }}
            Duration: {{ job.delta }}
            {% endif %}
          {% endfor %}
    
    - name: Wait if tasks still running
      pause:
        seconds: 5
      when: current_status.results | selectattr('finished', 'equalto', 0) | list | length > 0
    
    - name: Continue monitoring
      include_tasks: monitor_jobs.yml
      when: current_status.results | selectattr('finished', 'equalto', 0) | list | length > 0
```

---

## ✅ Lab Validation

### Create Validation Playbook

Create `playbooks/validate-lab2.yml`:

```yaml
---
- name: Validate Lab 2 Completion
  hosts: local
  gather_facts: yes
  
  tasks:
    - name: Check scripts exist
      stat:
        path: "{{ item }}"
      loop:
        - /tmp/long_task.sh
        - /tmp/backup_simulation.sh
      register: scripts_check
    
    - name: Check backup directory
      stat:
        path: /var/backups
      register: backup_dir
      become: yes
    
    - name: Find backup files
      find:
        paths: /var/backups
        patterns: "*.tar.gz"
      register: backup_files
      become: yes
    
    - name: Run async task test
      command: echo "Async test"
      async: 10
      poll: 0
      register: async_test
    
    - name: Check async test status
      async_status:
        jid: "{{ async_test.ansible_job_id }}"
      register: async_result
    
    - name: Validation Summary
      debug:
        msg: |
          Lab 2 Validation Results
          ========================
          ✅ Scripts created: {{ scripts_check.results | selectattr('stat.exists') | list | length }}/2
          ✅ Backup directory exists: {{ backup_dir.stat.exists }}
          ✅ Backup files created: {{ backup_files.files | length }}
          ✅ Async execution works: {{ async_result.finished is defined }}
          
          {% if scripts_check.results | selectattr('stat.exists') | list | length == 2 and backup_dir.stat.exists and async_result.finished is defined %}
          🎉 All validations passed! Lab 2 completed successfully!
          {% else %}
          ⚠️  Some validations failed. Review the playbook execution.
          {% endif %}
```

Run validation:

```bash
ansible-playbook -i inventory/hosts.ini playbooks/validate-lab2.yml
```

---

## 🎓 What You Learned

- ✅ Executed long-running tasks asynchronously
- ✅ Implemented fire-and-forget pattern
- ✅ Monitored async tasks with polling
- ✅ Ran multiple tasks in parallel
- ✅ Checked status of background jobs
- ✅ Handled timeouts and errors
- ✅ Optimized playbook performance

---

## 🚀 Challenge Exercises

### Challenge 1: Distributed Backup System

Create a playbook that:
- Backs up multiple servers simultaneously
- Monitors progress in real-time
- Sends notification when all complete
- Handles failures gracefully

### Challenge 2: Parallel Software Updates

Create a playbook that:
- Updates packages on all servers in parallel
- Monitors each server's progress
- Reboots servers if needed
- Verifies all servers are healthy

### Challenge 3: Load Test Orchestration

Create a playbook that:
- Launches load tests on multiple servers
- Collects results asynchronously
- Aggregates performance metrics
- Generates summary report

---

## 📚 Additional Resources

- [Async Actions Documentation](https://docs.ansible.com/ansible/latest/user_guide/playbooks_async.html)
- [async_status Module](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/async_status_module.html)
- [Performance Optimization](https://docs.ansible.com/ansible/latest/user_guide/playbooks_strategies.html)

---

## 🔄 Clean Up

```bash
# Clean up test files
rm -f /tmp/long_task.sh
rm -f /tmp/backup_simulation.sh
rm -f /tmp/job_id.txt
sudo rm -rf /tmp/backup_*

# Keep playbooks for future reference
```

---

**Congratulations! You've completed Lab 2! 🎉**

Next: Move on to Topic 3 - Check Mode ("Dry Run")
