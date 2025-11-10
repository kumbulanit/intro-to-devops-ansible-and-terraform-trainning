# Lab 5: Delegation and Rolling Updates

## 🎯 Lab Objectives

By completing this lab, you will:

- ✅ Use task delegation with `delegate_to`
- ✅ Implement `run_once` for single-execution tasks
- ✅ Perform rolling updates with `serial`
- ✅ Control batch execution and failure handling
- ✅ Orchestrate multi-tier deployments
- ✅ Implement zero-downtime deployment patterns

## ⏱️ Estimated Time

60 minutes

---

## 🔧 Lab Setup

### Prerequisites

- Ansible 2.9+ installed
- Multiple test servers (or use localhost for simulation)
- Text editor

### Create Lab Directory

```bash
mkdir -p ~/ansible-labs/lab5-rolling-updates
cd ~/ansible-labs/lab5-rolling-updates
```

### Create Inventory File

```bash
cat > inventory.ini << 'EOF'
[local]
localhost ansible_connection=local

[webservers]
web1 ansible_host=localhost ansible_connection=local ansible_port=8081
web2 ansible_host=localhost ansible_connection=local ansible_port=8082
web3 ansible_host=localhost ansible_connection=local ansible_port=8083
web4 ansible_host=localhost ansible_connection=local ansible_port=8084

[databases]
db1 ansible_host=localhost ansible_connection=local

[loadbalancers]
lb1 ansible_host=localhost ansible_connection=local

# For OpenStack instances (uncomment and update)
# [webservers]
# web1 ansible_host=<floating_ip_1> ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/openstack_key
# web2 ansible_host=<floating_ip_2> ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/openstack_key
# web3 ansible_host=<floating_ip_3> ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/openstack_key
# web4 ansible_host=<floating_ip_4> ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/openstack_key
#
# [databases]
# db1 ansible_host=<floating_ip_5> ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/openstack_key
#
# [loadbalancers]
# lb1 ansible_host=<floating_ip_6> ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/openstack_key

[all:vars]
ansible_python_interpreter=/usr/bin/python3
EOF
```

---

## 📝 Exercise 1: Basic Task Delegation

### Objective

Learn to delegate tasks to different hosts.

### Step 1: Create Basic Delegation Playbook

```bash
cat > exercise1-delegation.yml << 'EOF'
---
- name: Exercise 1 - Task Delegation
  hosts: webservers
  gather_facts: yes
  
  tasks:
    - name: Display current host
      debug:
        msg: "Currently processing: {{ inventory_hostname }}"
    
    - name: Create local log entry (delegated to localhost)
      lineinfile:
        path: /tmp/deployment-log.txt
        line: "{{ ansible_date_time.iso8601 }} - Processing {{ inventory_hostname }}"
        create: yes
      delegate_to: localhost
      # This task runs on localhost for each webserver
    
    - name: Notify monitoring server (simulated)
      debug:
        msg: "Notifying monitoring about {{ inventory_hostname }}"
      delegate_to: localhost
      run_once: true
      # Runs only once on localhost, not for each webserver
    
    - name: Check database status (delegated to db1)
      command: echo "Checking database for {{ inventory_hostname }}"
      delegate_to: db1
      register: db_status
      changed_when: false
    
    - name: Show database check result
      debug:
        msg: "Database status from db1: {{ db_status.stdout }}"
EOF
```

### Step 2: Run the Playbook

```bash
ansible-playbook -i inventory.ini exercise1-delegation.yml
```

### Expected Output

```
PLAY [Exercise 1 - Task Delegation] ********************************************

TASK [Display current host] ****************************************************
ok: [web1] => {
    "msg": "Currently processing: web1"
}
ok: [web2] => {
    "msg": "Currently processing: web2"
}
ok: [web3] => {
    "msg": "Currently processing: web3"
}
ok: [web4] => {
    "msg": "Currently processing: web4"
}

TASK [Create local log entry (delegated to localhost)] *************************
changed: [web1 -> localhost]
changed: [web2 -> localhost]
changed: [web3 -> localhost]
changed: [web4 -> localhost]

TASK [Notify monitoring server (simulated)] ************************************
ok: [web1 -> localhost] => {
    "msg": "Notifying monitoring about web1"
}

TASK [Check database status (delegated to db1)] ********************************
ok: [web1 -> db1]
ok: [web2 -> db1]
ok: [web3 -> db1]
ok: [web4 -> db1]
```

### Step 3: Verify Results

```bash
# Check the log file created on localhost
cat /tmp/deployment-log.txt
# Should show entries for all 4 webservers
```

### Validation

```bash
# Count log entries (should be 4)
wc -l /tmp/deployment-log.txt
```

---

## 📝 Exercise 2: Run Once Pattern

### Objective

Use `run_once` for operations that should execute only once.

### Step 1: Create Run Once Playbook

```bash
cat > exercise2-run-once.yml << 'EOF'
---
- name: Exercise 2 - Run Once Pattern
  hosts: webservers
  gather_facts: no
  
  vars:
    deploy_version: "2.0.0"
    shared_resource: "/tmp/shared-config.yml"
  
  tasks:
    - name: Create shared configuration (only once)
      copy:
        content: |
          version: {{ deploy_version }}
          deployment_time: {{ ansible_date_time.iso8601 }}
          servers:
          {% for host in groups['webservers'] %}
            - {{ host }}
          {% endfor %}
        dest: "{{ shared_resource }}"
      delegate_to: localhost
      run_once: true
      # Creates file once on localhost, not 4 times
    
    - name: Send deployment start email (simulated)
      debug:
        msg: |
          Sending email:
          Subject: Deployment Started
          To: ops-team@example.com
          Body: Deploying version {{ deploy_version }} to {{ groups['webservers'] | length }} servers
      delegate_to: localhost
      run_once: true
      # Sends one email, not one per server
    
    - name: Read shared configuration (each server)
      shell: cat {{ shared_resource }}
      delegate_to: localhost
      register: shared_config
      changed_when: false
    
    - name: Display configuration on each server
      debug:
        msg: "Server {{ inventory_hostname }} sees config: {{ shared_config.stdout_lines[0] }}"
    
    - name: Send deployment complete email (simulated)
      debug:
        msg: |
          Sending email:
          Subject: Deployment Complete
          To: ops-team@example.com
          Body: Successfully deployed to {{ ansible_play_hosts | length }} servers
      delegate_to: localhost
      run_once: true
      when: ansible_play_hosts_all | length == ansible_play_hosts | length
      # Only sends if all hosts completed successfully
EOF
```

### Step 2: Run the Playbook

```bash
ansible-playbook -i inventory.ini exercise2-run-once.yml
```

### Expected Output

```
TASK [Create shared configuration (only once)] *********************************
changed: [web1 -> localhost]

TASK [Send deployment start email (simulated)] *********************************
ok: [web1 -> localhost] => {
    "msg": "Sending email:\nSubject: Deployment Started\n..."
}

TASK [Read shared configuration (each server)] *********************************
ok: [web1 -> localhost]
ok: [web2 -> localhost]
ok: [web3 -> localhost]
ok: [web4 -> localhost]

TASK [Display configuration on each server] ************************************
ok: [web1] => {
    "msg": "Server web1 sees config: version: 2.0.0"
}
ok: [web2] => {
    "msg": "Server web2 sees config: version: 2.0.0"
}
...
```

### Validation

```bash
# Verify shared config exists
cat /tmp/shared-config.yml
```

---

## 📝 Exercise 3: Serial Rolling Updates

### Objective

Implement rolling updates with batch control.

### Step 1: Create Simulated Application

```bash
# Create application directories for each web server
for i in {1..4}; do
  mkdir -p /tmp/web${i}/app
  echo "version: 1.0.0" > /tmp/web${i}/app/version.txt
  echo "status: running" > /tmp/web${i}/app/status.txt
done
```

### Step 2: Create Rolling Update Playbook

```bash
cat > exercise3-rolling-update.yml << 'EOF'
---
- name: Exercise 3 - Rolling Update
  hosts: webservers
  serial: 2  # Update 2 servers at a time
  gather_facts: no
  
  vars:
    new_version: "2.0.0"
    app_dir: "/tmp/{{ inventory_hostname }}/app"
  
  tasks:
    - name: Show update batch
      debug:
        msg: |
          Updating batch: {{ ansible_play_batch }}
          Current host: {{ inventory_hostname }}
          Batch {{ ansible_play_batch.index(inventory_hostname) + 1 }} of {{ ansible_play_batch | length }}
    
    - name: Remove from load balancer (simulated)
      debug:
        msg: "Removing {{ inventory_hostname }} from load balancer"
      delegate_to: lb1
    
    - name: Wait for connection drain
      pause:
        seconds: 2
        prompt: "Draining connections from {{ inventory_hostname }}"
    
    - name: Stop application (simulated)
      lineinfile:
        path: "{{ app_dir }}/status.txt"
        regexp: '^status:'
        line: "status: stopped"
    
    - name: Backup current version
      copy:
        src: "{{ app_dir }}/version.txt"
        dest: "{{ app_dir }}/version.txt.backup"
        remote_src: yes
    
    - name: Deploy new version
      lineinfile:
        path: "{{ app_dir }}/version.txt"
        regexp: '^version:'
        line: "version: {{ new_version }}"
      register: deploy_result
    
    - name: Start application (simulated)
      lineinfile:
        path: "{{ app_dir }}/status.txt"
        regexp: '^status:'
        line: "status: running"
    
    - name: Verify deployment
      shell: cat {{ app_dir }}/version.txt
      register: verify_version
      changed_when: false
    
    - name: Assert correct version
      assert:
        that:
          - new_version in verify_version.stdout
        fail_msg: "Version mismatch on {{ inventory_hostname }}"
        success_msg: "{{ inventory_hostname }}: Deployed {{ new_version }} successfully"
    
    - name: Add back to load balancer (simulated)
      debug:
        msg: "Adding {{ inventory_hostname }} back to load balancer"
      delegate_to: lb1
    
    - name: Wait before next batch
      pause:
        seconds: 3
        prompt: "Batch complete. Waiting before next batch..."
      when: inventory_hostname == ansible_play_batch[-1]
      # Only pause after last host in each batch
EOF
```

### Step 3: Run Rolling Update

```bash
ansible-playbook -i inventory.ini exercise3-rolling-update.yml
```

### Expected Output

```
PLAY [Exercise 3 - Rolling Update] *********************************************

TASK [Show update batch] *******************************************************
ok: [web1] => {
    "msg": "Updating batch: ['web1', 'web2']\nCurrent host: web1\nBatch 1 of 2"
}
ok: [web2] => {
    "msg": "Updating batch: ['web1', 'web2']\nCurrent host: web2\nBatch 2 of 2"
}

TASK [Remove from load balancer (simulated)] ***********************************
ok: [web1 -> lb1]
ok: [web2 -> lb1]

... (updates web1 and web2) ...

TASK [Wait before next batch] **************************************************
Pausing for 3 seconds (Batch complete. Waiting before next batch...)

... (then updates web3 and web4) ...
```

### Validation

```bash
# Verify all servers updated
for i in {1..4}; do
  echo "web${i}:"
  cat /tmp/web${i}/app/version.txt
done
```

---

## 📝 Exercise 4: Percentage-Based Rolling Update

### Objective

Use percentage-based batching for scalable updates.

### Step 1: Create Percentage Rolling Playbook

```bash
cat > exercise4-percentage-rolling.yml << 'EOF'
---
- name: Exercise 4 - Percentage-Based Rolling
  hosts: webservers
  serial: "50%"  # Update 50% at a time (2 out of 4 servers)
  gather_facts: no
  
  vars:
    new_version: "3.0.0"
  
  tasks:
    - name: Show batch information
      debug:
        msg: |
          Total hosts: {{ ansible_play_hosts_all | length }}
          Current batch size: {{ ansible_play_batch | length }}
          Current batch: {{ ansible_play_batch }}
          Percentage: 50%
    
    - name: Update application
      lineinfile:
        path: "/tmp/{{ inventory_hostname }}/app/version.txt"
        regexp: '^version:'
        line: "version: {{ new_version }}"
EOF
```

### Step 2: Run the Playbook

```bash
ansible-playbook -i inventory.ini exercise4-percentage-rolling.yml
```

---

## 📝 Exercise 5: Staged Rolling Update (Canary)

### Objective

Implement canary deployment with multiple batch stages.

### Step 1: Create Canary Deployment Playbook

```bash
cat > exercise5-canary-deployment.yml << 'EOF'
---
- name: Exercise 5 - Canary Deployment
  hosts: webservers
  serial:
    - 1      # First server (canary)
    - 25%    # Next 25% (1 more server)
    - 100%   # Remaining servers (2 servers)
  gather_facts: no
  
  vars:
    new_version: "4.0.0"
    app_dir: "/tmp/{{ inventory_hostname }}/app"
  
  tasks:
    - name: Identify deployment stage
      set_fact:
        deployment_stage: >-
          {%- if ansible_play_batch | length == 1 -%}
            CANARY
          {%- elif ansible_play_batch | length <= 2 -%}
            EARLY_ADOPTER
          {%- else -%}
            GENERAL_AVAILABILITY
          {%- endif -%}
    
    - name: Announce deployment stage
      debug:
        msg: |
          ═══════════════════════════════════════════════
          🚀 DEPLOYMENT STAGE: {{ deployment_stage }}
          ═══════════════════════════════════════════════
          Updating: {{ inventory_hostname }}
          Batch: {{ ansible_play_batch }}
          Stage size: {{ ansible_play_batch | length }} server(s)
      run_once: true
    
    - name: Deploy to {{ inventory_hostname }}
      lineinfile:
        path: "{{ app_dir }}/version.txt"
        regexp: '^version:'
        line: "version: {{ new_version }}"
      register: deploy
    
    - name: Verify deployment
      shell: cat {{ app_dir }}/version.txt
      register: version_check
      changed_when: false
    
    - name: Health check
      shell: |
        if grep -q "{{ new_version }}" {{ app_dir }}/version.txt && \
           grep -q "status: running" {{ app_dir }}/status.txt; then
          echo "healthy"
        else
          echo "unhealthy"
        fi
      register: health
      changed_when: false
    
    - name: Assert healthy
      assert:
        that:
          - "'healthy' in health.stdout"
        fail_msg: "Health check failed on {{ inventory_hostname }}"
    
    - name: Wait for stability after canary
      pause:
        seconds: 5
        prompt: "Canary deployed. Monitoring for issues..."
      when:
        - deployment_stage == "CANARY"
        - inventory_hostname == ansible_play_batch[-1]
    
    - name: Wait for stability after early adopters
      pause:
        seconds: 3
        prompt: "Early adopters complete. Ready for GA..."
      when:
        - deployment_stage == "EARLY_ADOPTER"
        - inventory_hostname == ansible_play_batch[-1]
    
    - name: Deployment stage complete
      debug:
        msg: "✅ {{ deployment_stage }} stage completed successfully"
      when: inventory_hostname == ansible_play_batch[-1]
EOF
```

### Step 2: Run Canary Deployment

```bash
ansible-playbook -i inventory.ini exercise5-canary-deployment.yml
```

### Expected Output

```
TASK [Announce deployment stage] ***********************************************
ok: [web1] => {
    "msg": "═══════════════════════════════════════════════\n🚀 DEPLOYMENT STAGE: CANARY\n..."
}

TASK [Deploy to web1] **********************************************************
changed: [web1]

TASK [Wait for stability after canary] *****************************************
Pausing for 5 seconds (Canary deployed. Monitoring for issues...)

... (then deploys to 1 more server - EARLY_ADOPTER) ...

... (then deploys to remaining 2 servers - GENERAL_AVAILABILITY) ...
```

### Validation

```bash
# Verify all servers have version 4.0.0
for i in {1..4}; do
  echo "web${i}: $(cat /tmp/web${i}/app/version.txt)"
done
```

---

## 📝 Exercise 6: Zero-Downtime Deployment (Advanced)

### Objective

Implement complete zero-downtime deployment pattern.

### Step 1: Setup Mock Load Balancer

```bash
# Create load balancer pool file
mkdir -p /tmp/lb
cat > /tmp/lb/pool.txt << 'EOF'
web1:8081:active
web2:8082:active
web3:8083:active
web4:8084:active
EOF

# Create helper scripts
cat > /tmp/lb/remove.sh << 'EOF'
#!/bin/bash
server=$1
sed -i.bak "s/${server}:\([0-9]*\):active/${server}:\1:inactive/" /tmp/lb/pool.txt
echo "Removed ${server} from pool"
cat /tmp/lb/pool.txt
EOF

cat > /tmp/lb/add.sh << 'EOF'
#!/bin/bash
server=$1
sed -i.bak "s/${server}:\([0-9]*\):inactive/${server}:\1:active/" /tmp/lb/pool.txt
echo "Added ${server} to pool"
cat /tmp/lb/pool.txt
EOF

chmod +x /tmp/lb/*.sh
```

### Step 2: Create Zero-Downtime Playbook

```bash
cat > exercise6-zero-downtime.yml << 'EOF'
---
- name: Exercise 6 - Zero-Downtime Deployment
  hosts: webservers
  serial: 1  # One at a time for true zero-downtime
  gather_facts: yes
  
  vars:
    new_version: "5.0.0"
    app_dir: "/tmp/{{ inventory_hostname }}/app"
    lb_pool: "/tmp/lb/pool.txt"
  
  pre_tasks:
    - name: Check current load balancer status
      shell: grep {{ inventory_hostname }} {{ lb_pool }}
      delegate_to: localhost
      register: lb_status
      changed_when: false
  
  tasks:
    #
    # Phase 1: Remove from load balancer
    #
    - name: Remove from load balancer
      command: /tmp/lb/remove.sh {{ inventory_hostname }}
      delegate_to: localhost
      register: lb_remove
    
    - name: Show removal result
      debug:
        msg: "{{ lb_remove.stdout_lines }}"
    
    - name: Wait for connection drain
      pause:
        seconds: 3
    
    #
    # Phase 2: Update application
    #
    - name: Stop application
      lineinfile:
        path: "{{ app_dir }}/status.txt"
        regexp: '^status:'
        line: "status: stopped"
    
    - name: Backup current version
      shell: |
        cp {{ app_dir }}/version.txt {{ app_dir }}/version.txt.backup-{{ ansible_date_time.epoch }}
      args:
        creates: "{{ app_dir }}/version.txt.backup-{{ ansible_date_time.epoch }}"
    
    - name: Deploy new version
      lineinfile:
        path: "{{ app_dir }}/version.txt"
        regexp: '^version:'
        line: "version: {{ new_version }}"
    
    - name: Start application
      lineinfile:
        path: "{{ app_dir }}/status.txt"
        regexp: '^status:'
        line: "status: running"
    
    #
    # Phase 3: Validate and re-add
    #
    - name: Wait for application startup
      pause:
        seconds: 2
    
    - name: Health check
      shell: |
        if grep -q "{{ new_version }}" {{ app_dir }}/version.txt && \
           grep -q "status: running" {{ app_dir }}/status.txt; then
          echo "HEALTHY"
          exit 0
        else
          echo "UNHEALTHY"
          exit 1
        fi
      register: health_check
      retries: 3
      delay: 2
      until: health_check.rc == 0
    
    - name: Validate version
      shell: cat {{ app_dir }}/version.txt
      register: version_verify
      changed_when: false
      failed_when: new_version not in version_verify.stdout
    
    - name: Add back to load balancer
      command: /tmp/lb/add.sh {{ inventory_hostname }}
      delegate_to: localhost
      register: lb_add
    
    - name: Show addition result
      debug:
        msg: "{{ lb_add.stdout_lines }}"
    
    - name: Verify in load balancer
      shell: grep {{ inventory_hostname }} {{ lb_pool }} | grep active
      delegate_to: localhost
      register: lb_verify
      retries: 3
      delay: 1
      until: lb_verify.rc == 0
      changed_when: false
    
    - name: Deployment successful
      debug:
        msg: |
          ✅ {{ inventory_hostname }} successfully updated to {{ new_version }}
          Status: In load balancer and serving traffic
  
  rescue:
    - name: Deployment failed - rollback
      block:
        - name: Stop application
          lineinfile:
            path: "{{ app_dir }}/status.txt"
            regexp: '^status:'
            line: "status: stopped"
        
        - name: Restore backup
          shell: |
            if [ -f {{ app_dir }}/version.txt.backup ]; then
              cp {{ app_dir }}/version.txt.backup {{ app_dir }}/version.txt
              echo "Restored backup"
            fi
          register: rollback
        
        - name: Start application
          lineinfile:
            path: "{{ app_dir }}/status.txt"
            regexp: '^status:'
            line: "status: running"
        
        - name: Re-add to load balancer
          command: /tmp/lb/add.sh {{ inventory_hostname }}
          delegate_to: localhost
        
        - name: Notify failure
          debug:
            msg: |
              ⚠️  DEPLOYMENT FAILED on {{ inventory_hostname }}
              Rolled back to previous version
              Server re-added to load balancer
        
        - name: Fail the play
          fail:
            msg: "Deployment failed on {{ inventory_hostname }}, rollback complete"
EOF
```

### Step 3: Run Zero-Downtime Deployment

```bash
ansible-playbook -i inventory.ini exercise6-zero-downtime.yml
```

### Expected Output

```
TASK [Remove from load balancer] ***********************************************
changed: [web1 -> localhost]

TASK [Show removal result] *****************************************************
ok: [web1] => {
    "msg": [
        "Removed web1 from pool",
        "web1:8081:inactive",
        "web2:8082:active",
        ...
    ]
}

... (deployment steps) ...

TASK [Add back to load balancer] ***********************************************
changed: [web1 -> localhost]

TASK [Deployment successful] ***************************************************
ok: [web1] => {
    "msg": "✅ web1 successfully updated to 5.0.0\nStatus: In load balancer..."
}
```

### Validation

```bash
# Check load balancer pool
cat /tmp/lb/pool.txt
# All servers should be active

# Check versions
for i in {1..4}; do
  echo "web${i}: $(cat /tmp/web${i}/app/version.txt)"
done
# All should show version: 5.0.0
```

---

## ✅ Lab Validation

```bash
cat > validate-lab5.yml << 'EOF'
---
- name: Validate Lab 5 - Rolling Updates
  hosts: local
  gather_facts: no
  
  tasks:
    - name: Check exercise files exist
      stat:
        path: "{{ item }}"
      loop:
        - exercise1-delegation.yml
        - exercise2-run-once.yml
        - exercise3-rolling-update.yml
        - exercise4-percentage-rolling.yml
        - exercise5-canary-deployment.yml
        - exercise6-zero-downtime.yml
      register: exercise_files
    
    - name: Verify all exercises created
      assert:
        that:
          - item.stat.exists
      loop: "{{ exercise_files.results }}"
    
    - name: Check deployment artifacts
      stat:
        path: "{{ item }}"
      loop:
        - /tmp/deployment-log.txt
        - /tmp/shared-config.yml
        - /tmp/web1/app/version.txt
        - /tmp/lb/pool.txt
      register: artifacts
    
    - name: Verify artifacts exist
      assert:
        that:
          - item.stat.exists
      loop: "{{ artifacts.results }}"
    
    - name: Verify final version
      shell: cat /tmp/web{{ item }}/app/version.txt
      loop: [1, 2, 3, 4]
      register: versions
      changed_when: false
    
    - name: Check all servers updated
      assert:
        that:
          - "'5.0.0' in item.stdout"
        fail_msg: "Server not updated: {{ item.item }}"
      loop: "{{ versions.results }}"
    
    - name: Lab 5 completed successfully
      debug:
        msg: "✅ All Lab 5 exercises completed! You've mastered rolling updates!"
EOF

ansible-playbook -i inventory.ini validate-lab5.yml
```

---

## 🎯 Key Takeaways

1. **delegate_to** runs tasks on different hosts
2. **run_once** executes tasks once across all hosts
3. **serial** controls batch size for rolling updates
4. Percentage-based batching scales with inventory size
5. Staged rollouts (canary) minimize risk
6. Zero-downtime requires careful orchestration
7. Always implement health checks and rollback

---

## 📚 Additional Resources

- Day 6 Lesson: `../05-delegation-rolling-updates.md`
- [Delegation Documentation](https://docs.ansible.com/ansible/latest/user_guide/playbooks_delegation.html)
- [Strategies Guide](https://docs.ansible.com/ansible/latest/user_guide/playbooks_strategies.html)

---

## 🎓 What's Next?

After completing this lab, you should be able to:

- Delegate tasks strategically
- Implement various rolling update patterns
- Perform zero-downtime deployments
- Handle failures gracefully

**Ready for the next topic? Continue to `06-environment-and-proxies.md`! 🚀**
