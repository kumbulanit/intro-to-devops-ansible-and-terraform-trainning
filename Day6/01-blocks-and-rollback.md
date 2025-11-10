# Topic 1: Blocks & Rollback

## 📚 Overview

Blocks in Ansible allow you to logically group tasks together and apply error handling, making your playbooks more robust and maintainable. This is essential for production deployments where you need to ensure proper rollback mechanisms.

### 🎯 Learning Objectives

By the end of this lesson, you will:
- ✅ Understand block, rescue, and always sections
- ✅ Implement error handling with rescue blocks
- ✅ Create rollback strategies using blocks
- ✅ Use always blocks for cleanup operations
- ✅ Apply blocks in real-world scenarios

### ⏱️ Estimated Time
- Theory: 45 minutes
- Lab: 45 minutes
- Total: 90 minutes

---

## 🧩 What Are Blocks?

Blocks allow you to group tasks together and apply common directives like `when`, `become`, or error handling to all tasks in the block.

### Basic Block Structure

```yaml
---
- name: Example of basic block
  hosts: webservers
  
  tasks:
    - name: Install and configure Apache
      block:
        - name: Install Apache
          apt:
            name: apache2
            state: present
        
        - name: Start Apache
          service:
            name: apache2
            state: started
      
      when: ansible_os_family == "Debian"
      become: yes
```

**Key Benefits:**
- Group related tasks logically
- Apply conditions to multiple tasks
- Simplified privilege escalation
- Better error handling

---

## 🚨 Error Handling with Rescue

The `rescue` block executes when any task in the main `block` fails.

### Block with Rescue Example

```yaml
---
- name: Database backup with error handling
  hosts: dbservers
  
  tasks:
    - name: Backup database with rescue
      block:
        - name: Create backup directory
          file:
            path: /backup
            state: directory
            mode: '0755'
        
        - name: Dump database
          shell: pg_dump mydb > /backup/mydb_{{ ansible_date_time.epoch }}.sql
          become: yes
          become_user: postgres
        
        - name: Compress backup
          archive:
            path: /backup/mydb_{{ ansible_date_time.epoch }}.sql
            dest: /backup/mydb_{{ ansible_date_time.epoch }}.sql.gz
            remove: yes
      
      rescue:
        - name: Log backup failure
          debug:
            msg: "Backup failed! Alerting administrator..."
        
        - name: Send alert email
          mail:
            to: admin@example.com
            subject: "Backup Failed on {{ inventory_hostname }}"
            body: "Database backup failed. Please investigate."
          delegate_to: localhost
        
        - name: Clean up partial files
          file:
            path: /backup/mydb_{{ ansible_date_time.epoch }}.sql
            state: absent
      
      become: yes
```

**When to Use Rescue:**
- Database operations that might fail
- Network operations with potential timeouts
- Complex deployments requiring rollback
- Operations that need cleanup on failure

---

## 🔄 Always Block - Guaranteed Execution

The `always` block runs regardless of whether the block succeeds or fails.

### Complete Block Structure

```yaml
---
- name: Deploy application with complete error handling
  hosts: appservers
  vars:
    app_version: "2.0.0"
    rollback_version: "1.9.5"
  
  tasks:
    - name: Deploy new application version
      block:
        # Main deployment tasks
        - name: Stop application
          systemd:
            name: myapp
            state: stopped
        
        - name: Backup current version
          command: cp -r /opt/myapp /opt/myapp.backup
        
        - name: Download new version
          get_url:
            url: "https://releases.example.com/myapp-{{ app_version }}.tar.gz"
            dest: "/tmp/myapp-{{ app_version }}.tar.gz"
        
        - name: Extract new version
          unarchive:
            src: "/tmp/myapp-{{ app_version }}.tar.gz"
            dest: /opt/myapp
            remote_src: yes
        
        - name: Start application
          systemd:
            name: myapp
            state: started
        
        - name: Wait for application to be ready
          uri:
            url: "http://localhost:8080/health"
            status_code: 200
          register: health_check
          until: health_check.status == 200
          retries: 5
          delay: 10
      
      rescue:
        # Rollback on failure
        - name: Alert about deployment failure
          debug:
            msg: "Deployment failed! Rolling back to version {{ rollback_version }}"
        
        - name: Stop failed application
          systemd:
            name: myapp
            state: stopped
          ignore_errors: yes
        
        - name: Restore backup
          command: cp -r /opt/myapp.backup /opt/myapp
        
        - name: Start rolled-back application
          systemd:
            name: myapp
            state: started
        
        - name: Verify rollback success
          uri:
            url: "http://localhost:8080/health"
            status_code: 200
          register: rollback_check
        
        - name: Fail if rollback didn't work
          fail:
            msg: "Rollback failed! Manual intervention required!"
          when: rollback_check.status != 200
      
      always:
        # Cleanup runs no matter what
        - name: Remove downloaded archive
          file:
            path: "/tmp/myapp-{{ app_version }}.tar.gz"
            state: absent
        
        - name: Log deployment attempt
          lineinfile:
            path: /var/log/myapp-deployments.log
            line: "{{ ansible_date_time.iso8601 }} - Deployment of {{ app_version }} attempted by {{ ansible_user_id }}"
            create: yes
        
        - name: Send notification
          debug:
            msg: "Deployment process completed. Check application status."
      
      become: yes
```

**Always Block Use Cases:**
- Cleanup temporary files
- Logging deployment attempts
- Sending notifications
- Releasing locks
- Closing connections

---

## 🎯 Real-World Scenarios

### Scenario 1: Database Migration with Rollback

```yaml
---
- name: Database migration with automatic rollback
  hosts: dbservers
  vars:
    migration_version: "v2.5.0"
  
  tasks:
    - name: Run database migration
      block:
        - name: Create backup before migration
          postgresql_db:
            name: production_db
            state: dump
            target: "/backup/db_before_{{ migration_version }}_{{ ansible_date_time.epoch }}.sql"
          become: yes
          become_user: postgres
        
        - name: Run migration scripts
          postgresql_query:
            db: production_db
            path_to_script: "/opt/migrations/{{ migration_version }}.sql"
          become: yes
          become_user: postgres
        
        - name: Verify migration
          postgresql_query:
            db: production_db
            query: "SELECT version FROM schema_migrations ORDER BY applied_at DESC LIMIT 1"
          register: current_version
          become: yes
          become_user: postgres
        
        - name: Fail if migration didn't apply
          fail:
            msg: "Migration verification failed"
          when: current_version.query_result[0].version != migration_version
      
      rescue:
        - name: Migration failed - starting rollback
          debug:
            msg: "Migration failed! Rolling back database..."
        
        - name: Drop failed migration objects
          postgresql_query:
            db: production_db
            query: "DELETE FROM schema_migrations WHERE version = '{{ migration_version }}'"
          become: yes
          become_user: postgres
          ignore_errors: yes
        
        - name: Restore database from backup
          postgresql_db:
            name: production_db
            state: restore
            target: "/backup/db_before_{{ migration_version }}_{{ ansible_date_time.epoch }}.sql"
          become: yes
          become_user: postgres
        
        - name: Verify rollback
          postgresql_query:
            db: production_db
            query: "SELECT COUNT(*) as count FROM information_schema.tables"
          register: rollback_verify
          become: yes
          become_user: postgres
        
        - name: Send rollback alert
          mail:
            to: devops@example.com
            subject: "Database Migration Rollback - {{ migration_version }}"
            body: "Migration {{ migration_version }} failed and was rolled back on {{ inventory_hostname }}"
          delegate_to: localhost
      
      always:
        - name: Log migration attempt
          copy:
            content: |
              Migration: {{ migration_version }}
              Date: {{ ansible_date_time.iso8601 }}
              Host: {{ inventory_hostname }}
              Status: {{ 'Success' if ansible_failed_task is not defined else 'Failed' }}
            dest: "/var/log/db-migrations/{{ migration_version }}.log"
          become: yes
```

### Scenario 2: Multi-Service Deployment with Rollback

```yaml
---
- name: Deploy microservices with coordinated rollback
  hosts: appservers
  vars:
    new_version: "3.0.0"
    services:
      - name: api-gateway
        port: 8080
      - name: auth-service
        port: 8081
      - name: data-service
        port: 8082
  
  tasks:
    - name: Deploy all services
      block:
        # Deploy each service
        - name: Deploy services
          include_tasks: deploy-service.yml
          loop: "{{ services }}"
          loop_control:
            loop_var: service
        
        # Health check all services
        - name: Wait for all services to be healthy
          uri:
            url: "http://localhost:{{ item.port }}/health"
            status_code: 200
          register: health_checks
          until: health_checks.status == 200
          retries: 5
          delay: 10
          loop: "{{ services }}"
        
        # Integration test
        - name: Run integration tests
          command: /opt/tests/integration-test.sh {{ new_version }}
          register: integration_result
        
        - name: Fail if integration tests failed
          fail:
            msg: "Integration tests failed"
          when: integration_result.rc != 0
      
      rescue:
        - name: Deployment or tests failed - rolling back all services
          debug:
            msg: "Deployment failed. Rolling back all services..."
        
        - name: Rollback each service
          include_tasks: rollback-service.yml
          loop: "{{ services }}"
          loop_control:
            loop_var: service
        
        - name: Verify rollback
          uri:
            url: "http://localhost:{{ item.port }}/health"
            status_code: 200
          loop: "{{ services }}"
          register: rollback_health
        
        - name: Report rollback status
          debug:
            msg: "All services rolled back successfully"
      
      always:
        - name: Capture deployment metrics
          uri:
            url: "http://metrics.example.com/api/deployments"
            method: POST
            body_format: json
            body:
              version: "{{ new_version }}"
              timestamp: "{{ ansible_date_time.iso8601 }}"
              status: "{{ 'success' if ansible_failed_task is not defined else 'failed' }}"
              host: "{{ inventory_hostname }}"
          delegate_to: localhost
```

---

## 💡 Best Practices

### 1. Always Have a Rollback Plan

```yaml
# ❌ BAD - No rollback strategy
- name: Deploy without rollback
  command: /opt/deploy.sh

# ✅ GOOD - Proper rollback
- name: Deploy with rollback capability
  block:
    - name: Deploy
      command: /opt/deploy.sh
  rescue:
    - name: Rollback
      command: /opt/rollback.sh
```

### 2. Use Blocks for Related Tasks

```yaml
# ❌ BAD - Scattered privilege escalation
- name: Install package
  apt:
    name: nginx
    state: present
  become: yes

- name: Start service
  service:
    name: nginx
    state: started
  become: yes

# ✅ GOOD - Block with single become
- name: Install and configure nginx
  block:
    - name: Install package
      apt:
        name: nginx
        state: present
    
    - name: Start service
      service:
        name: nginx
        state: started
  become: yes
```

### 3. Clean Up in Always Block

```yaml
- name: Temporary work with cleanup
  block:
    - name: Create temp directory
      file:
        path: /tmp/workdir
        state: directory
    
    - name: Do work
      command: /opt/process.sh
      args:
        chdir: /tmp/workdir
  
  always:
    - name: Clean up temp directory
      file:
        path: /tmp/workdir
        state: absent
```

### 4. Meaningful Rescue Actions

```yaml
# ❌ BAD - Empty rescue
- name: Deploy
  block:
    - name: Deploy app
      command: deploy.sh
  rescue:
    - debug:
        msg: "Failed"

# ✅ GOOD - Actionable rescue
- name: Deploy with meaningful rescue
  block:
    - name: Deploy app
      command: deploy.sh
  rescue:
    - name: Capture error details
      command: journalctl -u myapp -n 50
      register: logs
    
    - name: Save error logs
      copy:
        content: "{{ logs.stdout }}"
        dest: "/var/log/deploy-failure-{{ ansible_date_time.epoch }}.log"
    
    - name: Notify team
      slack:
        token: "{{ slack_token }}"
        msg: "Deployment failed on {{ inventory_hostname }}"
```

---

## 🔍 Common Patterns

### Pattern 1: Backup-Deploy-Verify-Rollback

```yaml
- name: Safe deployment pattern
  block:
    - name: Backup current state
      archive:
        path: /opt/app
        dest: /backup/app_{{ ansible_date_time.epoch }}.tar.gz
    
    - name: Deploy new version
      unarchive:
        src: app-new.tar.gz
        dest: /opt/app
    
    - name: Restart service
      systemd:
        name: app
        state: restarted
    
    - name: Verify deployment
      uri:
        url: http://localhost/health
        status_code: 200
  
  rescue:
    - name: Restore from backup
      unarchive:
        src: /backup/app_{{ ansible_date_time.epoch }}.tar.gz
        dest: /opt/app
    
    - name: Restart with old version
      systemd:
        name: app
        state: restarted
```

### Pattern 2: Progressive Rollout with Canary

```yaml
- name: Canary deployment
  block:
    - name: Deploy to canary server
      include_role:
        name: deploy
      when: inventory_hostname == groups['canary'][0]
    
    - name: Monitor canary
      uri:
        url: "http://{{ groups['canary'][0] }}/metrics"
      register: canary_metrics
      until: canary_metrics.status == 200
      retries: 10
      delay: 30
    
    - name: Deploy to all if canary healthy
      include_role:
        name: deploy
      when: inventory_hostname in groups['production']
  
  rescue:
    - name: Rollback canary
      include_role:
        name: rollback
      when: inventory_hostname == groups['canary'][0]
```

---

## 🐛 Troubleshooting

### Common Issues

#### Issue 1: Rescue Block Not Executing

**Problem**: Rescue doesn't run when expected

```yaml
# This won't trigger rescue - ignore_errors bypasses it
- block:
    - command: /bin/false
      ignore_errors: yes
  rescue:
    - debug: msg="Never runs"
```

**Solution**: Remove `ignore_errors` or use different error handling

```yaml
- block:
    - command: /bin/false
      register: result
    - fail:
        msg: "Command failed"
      when: result.rc != 0
  rescue:
    - debug: msg="Now this runs"
```

#### Issue 2: Variables Not Available in Rescue

**Problem**: Need failed task info in rescue

**Solution**: Use `ansible_failed_task` and `ansible_failed_result`

```yaml
- block:
    - command: /opt/deploy.sh
      register: deploy_result
  rescue:
    - debug:
        msg: |
          Failed task: {{ ansible_failed_task.name }}
          Error: {{ ansible_failed_result.msg }}
```

---

## 📝 Summary

**Key Takeaways:**

1. **Blocks** group related tasks together
2. **Rescue** handles errors gracefully
3. **Always** ensures cleanup happens
4. Use blocks for deployment, migration, and complex operations
5. Always implement rollback strategies
6. Clean up resources in always blocks
7. Log all deployment attempts

**Next Steps:**
- Complete Lab 1: Database Migration with Rollback
- Practice the patterns in your own playbooks
- Move on to Topic 2: Asynchronous Actions and Polling

---

## 📖 Additional Resources

- [Official Docs: Error Handling](https://docs.ansible.com/ansible/latest/user_guide/playbooks_error_handling.html)
- [Official Docs: Blocks](https://docs.ansible.com/ansible/latest/user_guide/playbooks_blocks.html)
- [Best Practices: Production Deployments](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)

---

**Ready for hands-on practice? Head to `labs/lab1-blocks-rescue.md`! 🚀**
