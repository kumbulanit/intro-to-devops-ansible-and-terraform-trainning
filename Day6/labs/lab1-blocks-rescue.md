# Lab 1: Blocks, Rescue, and Always - Database Migration with Rollback

## 🎯 Lab Objectives

In this lab, you will:

- Create playbooks using block, rescue, and always sections
- Implement automatic rollback on failure
- Practice error handling in real-world scenarios
- Deploy a database migration with safety mechanisms
- Test both success and failure scenarios

## ⏱️ Estimated Time

90 minutes

## 📋 Prerequisites

- Completed Day 1-5 lessons
- Access to your OpenStack instance or test servers
- Ansible 2.9 or higher installed
- Basic understanding of PostgreSQL or MySQL

## 🏗️ Lab Environment Setup

### Option 1: Using Your OpenStack Instance

```bash
# SSH into your OpenStack instance
ssh -i ~/.ssh/openstack_key ubuntu@<your-instance-ip>

# Install PostgreSQL
sudo apt update
sudo apt install -y postgresql postgresql-contrib python3-psycopg2

# Start PostgreSQL
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

### Option 2: Using Docker (Alternative)

```bash
# Run PostgreSQL in Docker
docker run --name lab-postgres \
  -e POSTGRES_PASSWORD=mysecretpassword \
  -e POSTGRES_DB=testdb \
  -p 5432:5432 \
  -d postgres:13

# Install psycopg2 for Ansible
pip3 install psycopg2-binary
```

### Option 3: Local Vagrant VM

```bash
# Create Vagrantfile
cat > Vagrantfile <<EOF
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/focal64"
  config.vm.network "private_network", ip: "192.168.56.10"
  config.vm.provision "shell", inline: <<-SHELL
    apt-get update
    apt-get install -y postgresql postgresql-contrib python3-psycopg2
    systemctl start postgresql
  SHELL
end
EOF

vagrant up
```

---

## 📝 Exercise 1: Basic Block with Rescue

### Step 1: Create Lab Directory

```bash
cd ~/ansible-labs
mkdir -p day6-lab1/{playbooks,inventory,migrations}
cd day6-lab1
```

### Step 2: Create Inventory File

```bash
cat > inventory/hosts.ini <<EOF
[dbservers]
dbserver1 ansible_host=localhost ansible_connection=local

[dbservers:vars]
ansible_python_interpreter=/usr/bin/python3
EOF
```

**For OpenStack instance:**

```ini
[dbservers]
dbserver1 ansible_host=<your-instance-ip> ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/openstack_key

[dbservers:vars]
ansible_python_interpreter=/usr/bin/python3
```

### Step 3: Create Basic Block Playbook

Create `playbooks/01-basic-block.yml`:

```yaml
---
- name: Basic Block Example
  hosts: dbservers
  become: yes
  
  tasks:
    - name: Simple block with rescue
      block:
        - name: Task that will succeed
          debug:
            msg: "This task succeeds"
        
        - name: Task that will fail
          command: /bin/false
        
        - name: This task won't run
          debug:
            msg: "You won't see this"
      
      rescue:
        - name: Rescue message
          debug:
            msg: "A task failed! Rescue block is running."
        
        - name: Show failed task info
          debug:
            msg: |
              Failed task: {{ ansible_failed_task.name }}
              Failed result: {{ ansible_failed_result }}
      
      always:
        - name: Always runs
          debug:
            msg: "This always runs, regardless of success or failure"
```

### Step 4: Run the Playbook

```bash
ansible-playbook -i inventory/hosts.ini playbooks/01-basic-block.yml
```

**Expected Output:**

```
TASK [Task that will succeed] ******************
ok: [dbserver1] => {
    "msg": "This task succeeds"
}

TASK [Task that will fail] *********************
fatal: [dbserver1]: FAILED! => {"changed": true, "cmd": ["/bin/false"], ...}

TASK [Rescue message] **************************
ok: [dbserver1] => {
    "msg": "A task failed! Rescue block is running."
}

TASK [Show failed task info] *******************
ok: [dbserver1] => {
    "msg": "Failed task: Task that will fail\n..."
}

TASK [Always runs] *****************************
ok: [dbserver1] => {
    "msg": "This always runs, regardless of success or failure"
}

PLAY RECAP *************************************
dbserver1 : ok=4    changed=0    unreachable=0    failed=0    skipped=0    rescued=1    
```

**📊 Analysis:**

- Notice "rescued=1" in the PLAY RECAP
- The third task never ran
- Rescue block caught the failure
- Always block ran after rescue

---

## 📝 Exercise 2: Database Backup with Error Handling

### Step 1: Set Up Test Database

Create `playbooks/02-setup-database.yml`:

```yaml
---
- name: Setup Test Database
  hosts: dbservers
  become: yes
  become_user: postgres
  
  tasks:
    - name: Create test database
      postgresql_db:
        name: labdb
        state: present
    
    - name: Create test table
      postgresql_query:
        db: labdb
        query: |
          CREATE TABLE IF NOT EXISTS users (
            id SERIAL PRIMARY KEY,
            username VARCHAR(50) NOT NULL,
            email VARCHAR(100),
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
          );
    
    - name: Insert test data
      postgresql_query:
        db: labdb
        query: |
          INSERT INTO users (username, email) VALUES 
          ('alice', 'alice@example.com'),
          ('bob', 'bob@example.com'),
          ('charlie', 'charlie@example.com')
          ON CONFLICT DO NOTHING;
```

Run the setup:

```bash
ansible-playbook -i inventory/hosts.ini playbooks/02-setup-database.yml
```

### Step 2: Create Backup Playbook with Error Handling

Create `playbooks/03-backup-with-rescue.yml`:

```yaml
---
- name: Database Backup with Error Handling
  hosts: dbservers
  become: yes
  vars:
    backup_dir: /var/backups/postgres
    timestamp: "{{ ansible_date_time.epoch }}"
  
  tasks:
    - name: Database backup with rescue
      block:
        - name: Ensure backup directory exists
          file:
            path: "{{ backup_dir }}"
            state: directory
            mode: '0755'
            owner: postgres
            group: postgres
        
        - name: Dump database
          postgresql_db:
            name: labdb
            state: dump
            target: "{{ backup_dir }}/labdb_{{ timestamp }}.sql"
          become_user: postgres
        
        - name: Compress backup
          archive:
            path: "{{ backup_dir }}/labdb_{{ timestamp }}.sql"
            dest: "{{ backup_dir }}/labdb_{{ timestamp }}.sql.gz"
            remove: yes
        
        - name: Verify backup exists
          stat:
            path: "{{ backup_dir }}/labdb_{{ timestamp }}.sql.gz"
          register: backup_file
        
        - name: Fail if backup doesn't exist
          fail:
            msg: "Backup file not found!"
          when: not backup_file.stat.exists
        
        - name: Show success message
          debug:
            msg: "Backup completed successfully: {{ backup_dir }}/labdb_{{ timestamp }}.sql.gz"
      
      rescue:
        - name: Log backup failure
          copy:
            content: |
              Backup failed at: {{ ansible_date_time.iso8601 }}
              Host: {{ inventory_hostname }}
              Error: {{ ansible_failed_result.msg | default('Unknown error') }}
            dest: "{{ backup_dir }}/backup_failure_{{ timestamp }}.log"
          become_user: postgres
        
        - name: Send alert
          debug:
            msg: "ALERT: Backup failed! Check {{ backup_dir }}/backup_failure_{{ timestamp }}.log"
        
        - name: Clean up partial files
          find:
            paths: "{{ backup_dir }}"
            patterns: "*{{ timestamp }}*"
          register: partial_files
        
        - name: Remove partial backup files
          file:
            path: "{{ item.path }}"
            state: absent
          loop: "{{ partial_files.files }}"
      
      always:
        - name: List all backups
          find:
            paths: "{{ backup_dir }}"
            patterns: "*.sql.gz"
          register: all_backups
        
        - name: Show backup inventory
          debug:
            msg: "Total backups: {{ all_backups.files | length }}"
        
        - name: Clean old backups (keep last 5)
          shell: ls -t {{ backup_dir }}/*.sql.gz | tail -n +6 | xargs -r rm
          when: all_backups.files | length > 5
```

### Step 3: Run Backup Playbook

```bash
ansible-playbook -i inventory/hosts.ini playbooks/03-backup-with-rescue.yml
```

**Expected Output:**

```
TASK [Dump database] ***************************
changed: [dbserver1]

TASK [Compress backup] *************************
changed: [dbserver1]

TASK [Verify backup exists] ********************
ok: [dbserver1]

TASK [Show success message] ********************
ok: [dbserver1] => {
    "msg": "Backup completed successfully: /var/backups/postgres/labdb_1234567890.sql.gz"
}

TASK [List all backups] ************************
ok: [dbserver1]

TASK [Show backup inventory] *******************
ok: [dbserver1] => {
    "msg": "Total backups: 1"
}
```

### Step 4: Test Failure Scenario

Create `playbooks/04-backup-with-failure.yml`:

```yaml
---
- name: Test Backup Failure Scenario
  hosts: dbservers
  become: yes
  vars:
    backup_dir: /var/backups/postgres
    timestamp: "{{ ansible_date_time.epoch }}"
  
  tasks:
    - name: Backup with intentional failure
      block:
        - name: Try to backup non-existent database
          postgresql_db:
            name: nonexistent_db
            state: dump
            target: "{{ backup_dir }}/backup_{{ timestamp }}.sql"
          become_user: postgres
      
      rescue:
        - name: Capture error details
          debug:
            msg: |
              ✅ Rescue block activated successfully!
              Failed task: {{ ansible_failed_task.name }}
              Error: {{ ansible_failed_result.msg }}
        
        - name: Log the failure
          copy:
            content: |
              Backup Failure Log
              ==================
              Time: {{ ansible_date_time.iso8601 }}
              Host: {{ inventory_hostname }}
              Task: {{ ansible_failed_task.name }}
              Error: {{ ansible_failed_result.msg }}
            dest: "{{ backup_dir }}/failure_{{ timestamp }}.log"
      
      always:
        - name: Cleanup notification
          debug:
            msg: "Cleanup completed - check logs for details"
```

Run the failure test:

```bash
ansible-playbook -i inventory/hosts.ini playbooks/04-backup-with-failure.yml
```

**Expected Output:**

```
TASK [Try to backup non-existent database] *****
fatal: [dbserver1]: FAILED! => {"changed": false, "msg": "database \"nonexistent_db\" does not exist"}

TASK [Capture error details] *******************
ok: [dbserver1] => {
    "msg": "✅ Rescue block activated successfully!\nFailed task: Try to backup non-existent database\nError: database \"nonexistent_db\" does not exist"
}

TASK [Log the failure] *************************
changed: [dbserver1]

TASK [Cleanup notification] ********************
ok: [dbserver1] => {
    "msg": "Cleanup completed - check logs for details"
}

PLAY RECAP *************************************
dbserver1 : ok=3    changed=1    unreachable=0    failed=0    skipped=0    rescued=1
```

---

## 📝 Exercise 3: Database Migration with Automatic Rollback

### Step 1: Create Migration Files

Create migration SQL files:

```bash
# Create successful migration
cat > migrations/v1.0.0.sql <<EOF
-- Migration v1.0.0: Add age column
ALTER TABLE users ADD COLUMN IF NOT EXISTS age INTEGER;
UPDATE users SET age = 25 WHERE username = 'alice';
UPDATE users SET age = 30 WHERE username = 'bob';
UPDATE users SET age = 28 WHERE username = 'charlie';
EOF

# Create failing migration
cat > migrations/v1.0.1_bad.sql <<EOF
-- Migration v1.0.1: Intentionally bad migration
ALTER TABLE users ADD COLUMN phone VARCHAR(20);
INSERT INTO nonexistent_table VALUES (1, 'test');  -- This will fail
EOF
```

### Step 2: Create Migration Playbook

Create `playbooks/05-migration-with-rollback.yml`:

```yaml
---
- name: Database Migration with Automatic Rollback
  hosts: dbservers
  become: yes
  vars:
    backup_dir: /var/backups/postgres
    migration_version: "{{ version | default('v1.0.0') }}"
    timestamp: "{{ ansible_date_time.epoch }}"
  
  tasks:
    - name: Database migration with rollback capability
      block:
        - name: Create pre-migration backup
          postgresql_db:
            name: labdb
            state: dump
            target: "{{ backup_dir }}/pre_migration_{{ migration_version }}_{{ timestamp }}.sql"
          become_user: postgres
          register: backup_result
        
        - name: Show backup location
          debug:
            msg: "Backup created: {{ backup_result.executed_commands }}"
        
        - name: Copy migration file to server
          copy:
            src: "../migrations/{{ migration_version }}.sql"
            dest: "/tmp/migration_{{ migration_version }}.sql"
            mode: '0644'
        
        - name: Execute migration
          postgresql_query:
            db: labdb
            path_to_script: "/tmp/migration_{{ migration_version }}.sql"
          become_user: postgres
          register: migration_result
        
        - name: Verify migration applied
          postgresql_query:
            db: labdb
            query: "SELECT column_name FROM information_schema.columns WHERE table_name = 'users'"
          become_user: postgres
          register: columns
        
        - name: Show current table structure
          debug:
            msg: "Current columns: {{ columns.query_result | map(attribute='column_name') | list }}"
        
        - name: Migration success message
          debug:
            msg: "✅ Migration {{ migration_version }} completed successfully!"
      
      rescue:
        - name: Migration failed - initiating rollback
          debug:
            msg: "❌ Migration {{ migration_version }} failed! Starting rollback..."
        
        - name: Capture error details
          set_fact:
            error_details: |
              Migration: {{ migration_version }}
              Failed Task: {{ ansible_failed_task.name }}
              Error: {{ ansible_failed_result.msg | default('Unknown error') }}
              Time: {{ ansible_date_time.iso8601 }}
        
        - name: Show error details
          debug:
            msg: "{{ error_details }}"
        
        - name: Drop database (for clean restore)
          postgresql_db:
            name: labdb
            state: absent
          become_user: postgres
        
        - name: Recreate database
          postgresql_db:
            name: labdb
            state: present
          become_user: postgres
        
        - name: Restore from backup
          postgresql_db:
            name: labdb
            state: restore
            target: "{{ backup_dir }}/pre_migration_{{ migration_version }}_{{ timestamp }}.sql"
          become_user: postgres
        
        - name: Verify rollback
          postgresql_query:
            db: labdb
            query: "SELECT COUNT(*) as count FROM users"
          become_user: postgres
          register: rollback_check
        
        - name: Show rollback result
          debug:
            msg: "✅ Rollback successful! User count: {{ rollback_check.query_result[0].count }}"
        
        - name: Save error log
          copy:
            content: "{{ error_details }}"
            dest: "{{ backup_dir }}/migration_failure_{{ migration_version }}_{{ timestamp }}.log"
        
        - name: Fail the play with clear message
          fail:
            msg: |
              Migration {{ migration_version }} failed and was rolled back.
              Original data restored from backup.
              Error log: {{ backup_dir }}/migration_failure_{{ migration_version }}_{{ timestamp }}.log
      
      always:
        - name: Clean up temporary migration file
          file:
            path: "/tmp/migration_{{ migration_version }}.sql"
            state: absent
        
        - name: Log migration attempt
          lineinfile:
            path: "{{ backup_dir }}/migration_history.log"
            line: "{{ ansible_date_time.iso8601 }} | {{ migration_version }} | {{ 'SUCCESS' if ansible_failed_task is not defined else 'FAILED' }} | {{ inventory_hostname }}"
            create: yes
        
        - name: Show migration history
          command: tail -n 5 {{ backup_dir }}/migration_history.log
          register: history
          changed_when: false
        
        - name: Display recent migrations
          debug:
            msg: "{{ history.stdout_lines }}"
```

### Step 3: Test Successful Migration

```bash
ansible-playbook -i inventory/hosts.ini playbooks/05-migration-with-rollback.yml
```

**Expected Output:**

```
TASK [Create pre-migration backup] *************
changed: [dbserver1]

TASK [Execute migration] ***********************
changed: [dbserver1]

TASK [Show current table structure] ************
ok: [dbserver1] => {
    "msg": "Current columns: ['id', 'username', 'email', 'created_at', 'age']"
}

TASK [Migration success message] ***************
ok: [dbserver1] => {
    "msg": "✅ Migration v1.0.0 completed successfully!"
}

TASK [Display recent migrations] ***************
ok: [dbserver1] => {
    "msg": [
        "2024-01-15T10:30:45Z | v1.0.0 | SUCCESS | dbserver1"
    ]
}
```

### Step 4: Test Failed Migration with Rollback

```bash
ansible-playbook -i inventory/hosts.ini playbooks/05-migration-with-rollback.yml -e "version=v1.0.1_bad"
```

**Expected Output:**

```
TASK [Create pre-migration backup] *************
changed: [dbserver1]

TASK [Execute migration] ***********************
fatal: [dbserver1]: FAILED! => {"msg": "relation \"nonexistent_table\" does not exist"}

TASK [Migration failed - initiating rollback] **
ok: [dbserver1] => {
    "msg": "❌ Migration v1.0.1_bad failed! Starting rollback..."
}

TASK [Restore from backup] *********************
changed: [dbserver1]

TASK [Show rollback result] ********************
ok: [dbserver1] => {
    "msg": "✅ Rollback successful! User count: 3"
}

TASK [Display recent migrations] ***************
ok: [dbserver1] => {
    "msg": [
        "2024-01-15T10:30:45Z | v1.0.0 | SUCCESS | dbserver1",
        "2024-01-15T10:35:22Z | v1.0.1_bad | FAILED | dbserver1"
    ]
}
```

### Step 5: Verify Database State

```bash
# Check that database was rolled back
ansible dbservers -i inventory/hosts.ini -m postgresql_query \
  -a "db=labdb query='SELECT * FROM users'" \
  --become --become-user=postgres
```

---

## 📝 Exercise 4: Multi-Step Deployment with Coordinated Rollback

### Step 1: Create Multi-Service Playbook

Create `playbooks/06-coordinated-deployment.yml`:

```yaml
---
- name: Multi-Step Deployment with Coordinated Rollback
  hosts: dbservers
  become: yes
  vars:
    app_version: "2.0.0"
    deployment_dir: /opt/myapp
  
  tasks:
    - name: Coordinated deployment
      block:
        # Step 1: Backup
        - name: Step 1 - Create deployment backup
          archive:
            path: "{{ deployment_dir }}"
            dest: "/backup/myapp_{{ ansible_date_time.epoch }}.tar.gz"
          when: deployment_dir is directory
          register: backup
        
        # Step 2: Database migration
        - name: Step 2 - Run database migration
          postgresql_query:
            db: labdb
            query: "ALTER TABLE users ADD COLUMN IF NOT EXISTS last_login TIMESTAMP"
          become_user: postgres
          register: db_migration
        
        # Step 3: Update application files
        - name: Step 3 - Create application directory
          file:
            path: "{{ deployment_dir }}"
            state: directory
            mode: '0755'
        
        - name: Step 3 - Deploy new application files
          copy:
            content: |
              #!/bin/bash
              # Application version {{ app_version }}
              echo "MyApp {{ app_version }} - Running"
              exit 0
            dest: "{{ deployment_dir }}/myapp.sh"
            mode: '0755'
        
        # Step 4: Verify deployment
        - name: Step 4 - Test application
          command: "{{ deployment_dir }}/myapp.sh"
          register: app_test
        
        - name: Step 4 - Verify app output
          assert:
            that:
              - app_test.rc == 0
              - "'Running' in app_test.stdout"
            fail_msg: "Application verification failed"
        
        # Step 5: Final health check
        - name: Step 5 - Database health check
          postgresql_query:
            db: labdb
            query: "SELECT COUNT(*) as count FROM users"
          become_user: postgres
          register: health_check
        
        - name: Success notification
          debug:
            msg: |
              ✅ Deployment {{ app_version }} completed successfully!
              - Backup: {{ backup.dest | default('N/A') }}
              - DB Migration: Successful
              - App Test: {{ app_test.stdout }}
              - Health Check: {{ health_check.query_result[0].count }} users
      
      rescue:
        - name: Deployment failed - Rolling back all changes
          debug:
            msg: "❌ Deployment failed at: {{ ansible_failed_task.name }}"
        
        - name: Rollback - Revert database migration
          postgresql_query:
            db: labdb
            query: "ALTER TABLE users DROP COLUMN IF EXISTS last_login"
          become_user: postgres
          ignore_errors: yes
        
        - name: Rollback - Restore application files
          unarchive:
            src: "{{ backup.dest }}"
            dest: /
            remote_src: yes
          when: backup is defined and backup.dest is defined
          ignore_errors: yes
        
        - name: Verify rollback
          command: "{{ deployment_dir }}/myapp.sh"
          register: rollback_test
          ignore_errors: yes
        
        - name: Rollback status
          debug:
            msg: |
              Rollback completed
              Status: {{ 'Success' if rollback_test.rc == 0 else 'Manual intervention required' }}
        
        - name: Fail with error report
          fail:
            msg: |
              Deployment failed and rollback completed.
              Failed step: {{ ansible_failed_task.name }}
              Error: {{ ansible_failed_result.msg | default('Unknown') }}
      
      always:
        - name: Capture deployment metrics
          copy:
            content: |
              Deployment Report
              =================
              Version: {{ app_version }}
              Time: {{ ansible_date_time.iso8601 }}
              Host: {{ inventory_hostname }}
              Status: {{ 'SUCCESS' if ansible_failed_task is not defined else 'FAILED' }}
              Failed Task: {{ ansible_failed_task.name | default('N/A') }}
            dest: "/var/log/deployment_{{ ansible_date_time.epoch }}.log"
```

### Step 2: Run Deployment

```bash
ansible-playbook -i inventory/hosts.ini playbooks/06-coordinated-deployment.yml
```

---

## ✅ Lab Validation

### Check Your Work

Run this validation playbook to verify everything worked:

Create `playbooks/validate-lab1.yml`:

```yaml
---
- name: Validate Lab 1 Completion
  hosts: dbservers
  become: yes
  
  tasks:
    - name: Check backup directory exists
      stat:
        path: /var/backups/postgres
      register: backup_dir
    
    - name: Check database exists
      postgresql_query:
        db: labdb
        query: "SELECT 1"
      become_user: postgres
      register: db_check
      ignore_errors: yes
    
    - name: Check users table
      postgresql_query:
        db: labdb
        query: "SELECT COUNT(*) as count FROM users"
      become_user: postgres
      register: user_count
      ignore_errors: yes
    
    - name: Check migration history log
      stat:
        path: /var/backups/postgres/migration_history.log
      register: history_log
    
    - name: Validation Results
      debug:
        msg: |
          Lab 1 Validation Results
          ========================
          ✅ Backup directory exists: {{ backup_dir.stat.exists }}
          ✅ Database accessible: {{ db_check is succeeded }}
          ✅ Users table has data: {{ user_count.query_result[0].count if user_count is succeeded else 0 }} users
          ✅ Migration history logged: {{ history_log.stat.exists }}
          
          {% if backup_dir.stat.exists and db_check is succeeded and user_count is succeeded and history_log.stat.exists %}
          🎉 All checks passed! Lab 1 completed successfully!
          {% else %}
          ⚠️  Some checks failed. Review the playbook execution.
          {% endif %}
```

Run validation:

```bash
ansible-playbook -i inventory/hosts.ini playbooks/validate-lab1.yml
```

---

## 🎓 What You Learned

- ✅ Created blocks to group related tasks
- ✅ Implemented rescue blocks for error handling
- ✅ Used always blocks for guaranteed cleanup
- ✅ Built automatic rollback mechanisms
- ✅ Tested both success and failure scenarios
- ✅ Created production-ready deployment patterns

---

## 🚀 Challenge Exercises

### Challenge 1: Web Server Deployment

Create a playbook that:
- Deploys nginx with block/rescue/always
- Backs up existing config
- Tests new config before applying
- Rolls back on failure
- Always restores service state

### Challenge 2: Application Update

Create a zero-downtime deployment that:
- Backs up current application
- Deploys new version
- Runs health checks
- Rolls back if health checks fail
- Logs all deployment attempts

### Challenge 3: Multi-Database Migration

Create a playbook that:
- Migrates multiple databases in sequence
- Rolls back ALL databases if any fail
- Maintains referential integrity
- Logs each step

---

## 📚 Additional Resources

- [Ansible Blocks Documentation](https://docs.ansible.com/ansible/latest/user_guide/playbooks_blocks.html)
- [PostgreSQL Module Docs](https://docs.ansible.com/ansible/latest/collections/community/postgresql/)
- [Error Handling Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_error_handling.html)

---

## 🔄 Clean Up

When you're done with the lab:

```bash
# Stop and remove Docker container (if used)
docker stop lab-postgres
docker rm lab-postgres

# Or destroy Vagrant VM (if used)
vagrant destroy -f

# Keep the playbooks for future reference!
```

---

**Congratulations! You've completed Lab 1! 🎉**

Next: Move on to Topic 2 - Asynchronous Actions and Polling
