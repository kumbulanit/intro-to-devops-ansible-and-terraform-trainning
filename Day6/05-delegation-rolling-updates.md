# Topic 5: Delegation, Rolling Updates, and Local Actions

## 📚 Overview

Delegation in Ansible allows you to execute tasks on different hosts than the play targets. Rolling updates enable zero-downtime deployments by updating hosts in batches. These patterns are essential for production deployments, load balancer management, and complex orchestration scenarios.

### 🎯 Learning Objectives

By the end of this lesson, you will:

- ✅ Understand task delegation with `delegate_to`
- ✅ Use `run_once` for single-execution tasks
- ✅ Implement rolling updates with `serial`
- ✅ Control batch execution and failure thresholds
- ✅ Perform local actions with `local_action`
- ✅ Orchestrate multi-tier deployments
- ✅ Implement zero-downtime deployment strategies

### ⏱️ Estimated Time

- Theory: 60 minutes
- Lab: 60 minutes
- Total: 120 minutes

---

## 🎯 Task Delegation

### Basic Delegation with delegate_to

Execute a task on a different host than the current play target:

```yaml
---
- name: Delegation Example
  hosts: webservers
  
  tasks:
    - name: Update load balancer (runs on lb server)
      command: /usr/local/bin/update-pool.sh
      delegate_to: loadbalancer.example.com
      # Task runs on loadbalancer, not webservers
    
    - name: Deploy application (runs on webservers)
      copy:
        src: app.war
        dest: /opt/tomcat/webapps/
      # Task runs on each webserver normally
```

### Common Delegation Patterns

#### 1. Delegate to Localhost

Run tasks on the Ansible control machine:

```yaml
---
- name: Delegate to Control Machine
  hosts: remote_servers
  
  tasks:
    - name: Create local backup of config
      copy:
        src: /etc/myapp/config.yml
        dest: /tmp/backup-{{ inventory_hostname }}-config.yml
      delegate_to: localhost
      # Copies from remote server to local machine
    
    - name: Generate report locally
      shell: |
        echo "Deployed to {{ inventory_hostname }}" >> /tmp/deployment-log.txt
      delegate_to: localhost
```

#### 2. Delegate to Another Host in Inventory

```yaml
---
- name: Cross-Host Operations
  hosts: appservers
  
  tasks:
    - name: Notify monitoring server
      uri:
        url: "http://{{ monitoring_server }}/api/deploy"
        method: POST
        body_format: json
        body:
          host: "{{ inventory_hostname }}"
          status: "deploying"
      delegate_to: "{{ monitoring_server }}"
```

---

## 🔄 Run Once Pattern

Execute a task only once, even when targeting multiple hosts:

### Basic run_once

```yaml
---
- name: Run Once Example
  hosts: webservers
  
  tasks:
    - name: Create shared directory (only once)
      file:
        path: /shared/app-data
        state: directory
      run_once: true
      # Runs on first host only
    
    - name: Deploy to all servers
      copy:
        src: app.jar
        dest: /opt/app/
      # Runs on all hosts
```

### run_once with Delegation

```yaml
---
- name: Run Once with Delegation
  hosts: appservers
  
  vars:
    deploy_timestamp: "{{ ansible_date_time.iso8601 }}"
  
  tasks:
    - name: Send deployment start notification
      mail:
        to: ops-team@example.com
        subject: "Deployment Started"
        body: "Deploying to {{ groups['appservers'] | length }} servers"
      delegate_to: localhost
      run_once: true
      # Sends one email, not one per server
    
    - name: Deploy application
      copy:
        src: application.jar
        dest: /opt/app/
    
    - name: Send deployment complete notification
      mail:
        to: ops-team@example.com
        subject: "Deployment Complete"
        body: "Deployed to all servers successfully"
      delegate_to: localhost
      run_once: true
      when: ansible_play_hosts_all | length == ansible_play_hosts | length
```

---

## 🎲 Rolling Updates with Serial

Update hosts in batches to maintain service availability:

### Basic Serial Execution

```yaml
---
- name: Rolling Update
  hosts: webservers
  serial: 2  # Update 2 hosts at a time
  
  tasks:
    - name: Remove from load balancer
      command: /usr/local/bin/lb-remove.sh {{ inventory_hostname }}
      delegate_to: loadbalancer
    
    - name: Stop application
      service:
        name: myapp
        state: stopped
    
    - name: Update application
      copy:
        src: app-v2.0.jar
        dest: /opt/app/application.jar
    
    - name: Start application
      service:
        name: myapp
        state: started
    
    - name: Add back to load balancer
      command: /usr/local/bin/lb-add.sh {{ inventory_hostname }}
      delegate_to: loadbalancer
```

### Percentage-Based Serial

```yaml
---
- name: Rolling Update with Percentages
  hosts: production_servers
  serial: "20%"  # Update 20% of hosts at a time
  
  tasks:
    - name: Deploy new version
      copy:
        src: application.jar
        dest: /opt/app/
```

### Multiple Serial Batches

Different batch sizes for different stages:

```yaml
---
- name: Staged Rolling Update
  hosts: webservers
  serial:
    - 1      # First host (canary)
    - 25%    # Then 25% of remaining
    - 100%   # Then all remaining
  
  tasks:
    - name: Deploy application
      copy:
        src: app.jar
        dest: /opt/app/
    
    - name: Validate deployment
      uri:
        url: "http://{{ inventory_hostname }}:8080/health"
        status_code: 200
      retries: 5
      delay: 10
    
    - name: Wait for stability
      pause:
        seconds: 30
      when: ansible_play_batch.index(inventory_hostname) == 0
      # Only pause for first host in each batch
```

---

## 🎯 Local Actions

Run tasks locally while iterating over remote hosts:

### local_action Directive

```yaml
---
- name: Local Action Example
  hosts: databases
  
  tasks:
    - name: Backup database locally
      local_action:
        module: shell
        cmd: |
          mysqldump -h {{ inventory_hostname }} \
                    -u backup_user \
                    -p{{ db_password }} \
                    {{ db_name }} > /backups/{{ inventory_hostname }}-{{ db_name }}.sql
      # Runs mysqldump on control machine for each database server
```

### Equivalent Delegation

```yaml
---
- name: Local Action with delegate_to
  hosts: databases
  
  tasks:
    - name: Backup database locally
      shell: |
        mysqldump -h {{ inventory_hostname }} \
                  -u backup_user \
                  -p{{ db_password }} \
                  {{ db_name }} > /backups/{{ inventory_hostname }}-{{ db_name }}.sql
      delegate_to: localhost
```

---

## 🎯 Real-World: Zero-Downtime Deployment

Complete zero-downtime deployment with load balancer integration:

```yaml
---
- name: Zero-Downtime Deployment
  hosts: webservers
  serial: 1  # One server at a time
  
  vars:
    lb_server: "lb.example.com"
    app_port: 8080
    health_check_url: "http://{{ inventory_hostname }}:{{ app_port }}/health"
  
  pre_tasks:
    - name: Check server is in load balancer
      shell: |
        curl -s http://{{ lb_server }}/api/pool | grep {{ inventory_hostname }}
      delegate_to: localhost
      register: lb_status
      failed_when: lb_status.rc not in [0, 1]
      changed_when: false
  
  tasks:
    #
    # Phase 1: Remove from load balancer
    #
    - name: Remove server from load balancer
      uri:
        url: "http://{{ lb_server }}/api/pool/remove"
        method: POST
        body_format: json
        body:
          server: "{{ inventory_hostname }}"
          port: "{{ app_port }}"
      delegate_to: localhost
      when: lb_status.rc == 0
    
    - name: Wait for connections to drain
      pause:
        seconds: 15
    
    - name: Verify no active connections
      shell: netstat -an | grep {{ app_port }} | grep ESTABLISHED | wc -l
      register: connections
      until: connections.stdout | int == 0
      retries: 6
      delay: 10
    
    #
    # Phase 2: Update application
    #
    - name: Stop application service
      service:
        name: myapp
        state: stopped
    
    - name: Backup current version
      command: |
        cp -r /opt/myapp/current /opt/myapp/backup-{{ ansible_date_time.epoch }}
      args:
        creates: /opt/myapp/backup-{{ ansible_date_time.epoch }}
    
    - name: Deploy new version
      copy:
        src: application-v2.0.jar
        dest: /opt/myapp/current/application.jar
      register: deploy_result
    
    - name: Update configuration
      template:
        src: application.properties.j2
        dest: /opt/myapp/current/config/application.properties
      notify: restart application
    
    - name: Start application service
      service:
        name: myapp
        state: started
    
    #
    # Phase 3: Validate and re-add to load balancer
    #
    - name: Wait for application to start
      wait_for:
        port: "{{ app_port }}"
        delay: 5
        timeout: 120
    
    - name: Run health check
      uri:
        url: "{{ health_check_url }}"
        status_code: 200
        return_content: yes
      register: health_check
      until: health_check.status == 200
      retries: 10
      delay: 6
    
    - name: Validate application version
      assert:
        that:
          - "'v2.0' in health_check.content"
        fail_msg: "Application version mismatch"
        success_msg: "Correct version deployed: v2.0"
    
    - name: Add server back to load balancer
      uri:
        url: "http://{{ lb_server }}/api/pool/add"
        method: POST
        body_format: json
        body:
          server: "{{ inventory_hostname }}"
          port: "{{ app_port }}"
      delegate_to: localhost
    
    - name: Verify server in load balancer
      shell: |
        curl -s http://{{ lb_server }}/api/pool | grep {{ inventory_hostname }}
      delegate_to: localhost
      register: lb_verify
      until: lb_verify.rc == 0
      retries: 5
      delay: 3
  
  rescue:
    - name: Deployment failed - rollback
      block:
        - name: Stop application
          service:
            name: myapp
            state: stopped
        
        - name: Restore backup
          shell: |
            rm -rf /opt/myapp/current/*
            cp -r /opt/myapp/backup-{{ ansible_date_time.epoch }}/* /opt/myapp/current/
        
        - name: Start application
          service:
            name: myapp
            state: started
        
        - name: Notify failure
          mail:
            to: ops-team@example.com
            subject: "Deployment Failed: {{ inventory_hostname }}"
            body: "Rolled back to previous version"
          delegate_to: localhost
          run_once: true
  
  handlers:
    - name: restart application
      service:
        name: myapp
        state: restarted
```

---

## 🎯 Failure Handling with max_fail_percentage

Control how many hosts can fail before aborting:

```yaml
---
- name: Controlled Rolling Update
  hosts: webservers
  serial: 5
  max_fail_percentage: 20  # Allow up to 20% to fail
  
  tasks:
    - name: Update application
      copy:
        src: app.jar
        dest: /opt/app/
    
    - name: Restart service
      service:
        name: myapp
        state: restarted
    
    - name: Validate deployment
      uri:
        url: "http://{{ inventory_hostname }}:8080/health"
        status_code: 200
      # If more than 20% of hosts fail validation, play aborts
```

### any_errors_fatal

Stop all hosts if any host fails:

```yaml
---
- name: Critical Deployment
  hosts: databases
  any_errors_fatal: true  # Stop everything on first failure
  serial: 1
  
  tasks:
    - name: Update database schema
      mysql_db:
        name: production_db
        state: import
        target: /tmp/schema-v2.sql
      # If this fails on any host, entire play stops
```

---

## 🎯 Complex Orchestration Example

Multi-tier application deployment with orchestration:

```yaml
---
- name: Multi-Tier Deployment Orchestration
  hosts: all
  gather_facts: yes
  
  tasks:
    #
    # Phase 1: Update databases (one at a time)
    #
    - name: Update database tier
      block:
        - name: Stop database replication
          mysql_replication:
            mode: stop
          when: inventory_hostname in groups['databases']
        
        - name: Apply database migrations
          mysql_db:
            name: appdb
            state: import
            target: /tmp/migrations.sql
          when: inventory_hostname in groups['databases']
          run_once: true  # Only one database needs to run migrations
        
        - name: Start database replication
          mysql_replication:
            mode: start
          when: inventory_hostname in groups['databases']
      when: inventory_hostname in groups['databases']
    
    #
    # Phase 2: Update application tier (rolling)
    #
    - name: Update application tier
      block:
        - name: Remove from load balancer
          command: lb-remove {{ inventory_hostname }}
          delegate_to: "{{ groups['loadbalancers'][0] }}"
        
        - name: Deploy new application version
          copy:
            src: app-v2.jar
            dest: /opt/app/
        
        - name: Restart application
          service:
            name: myapp
            state: restarted
        
        - name: Wait for health check
          uri:
            url: "http://{{ inventory_hostname }}:8080/health"
            status_code: 200
          retries: 10
          delay: 6
        
        - name: Add back to load balancer
          command: lb-add {{ inventory_hostname }}
          delegate_to: "{{ groups['loadbalancers'][0] }}"
      when: inventory_hostname in groups['appservers']
    
    #
    # Phase 3: Update load balancer configuration
    #
    - name: Update load balancer
      block:
        - name: Update load balancer config
          template:
            src: lb-config.j2
            dest: /etc/haproxy/haproxy.cfg
          notify: reload haproxy
        
        - name: Validate configuration
          command: haproxy -c -f /etc/haproxy/haproxy.cfg
      when: inventory_hostname in groups['loadbalancers']
  
  handlers:
    - name: reload haproxy
      service:
        name: haproxy
        state: reloaded
```

---

## 🎯 Best Practices

### 1. Use Serial for Production Deployments

```yaml
# ✅ GOOD - Rolling updates
- hosts: production
  serial: "25%"  # 25% at a time
  max_fail_percentage: 10
```

### 2. Always Validate After Deployment

```yaml
# ✅ GOOD - Validation steps
- name: Deploy and validate
  block:
    - name: Deploy application
      copy:
        src: app.jar
        dest: /opt/app/
    
    - name: Restart service
      service:
        name: myapp
        state: restarted
    
    - name: Health check
      uri:
        url: "http://localhost:8080/health"
        status_code: 200
      retries: 10
      delay: 6
```

### 3. Use run_once for Shared Resources

```yaml
# ✅ GOOD - One-time operations
- name: Create shared database
  mysql_db:
    name: shared_db
    state: present
  run_once: true
  delegate_to: "{{ groups['databases'][0] }}"
```

### 4. Implement Proper Rollback

```yaml
# ✅ GOOD - Rollback on failure
- name: Deploy with rollback
  block:
    - name: Backup current version
      command: cp /opt/app/current.jar /opt/app/backup.jar
    
    - name: Deploy new version
      copy:
        src: new.jar
        dest: /opt/app/current.jar
  
  rescue:
    - name: Rollback to previous version
      command: cp /opt/app/backup.jar /opt/app/current.jar
```

---

## 💡 Common Patterns

### Pattern 1: Canary Deployment

```yaml
- hosts: webservers
  serial:
    - 1      # Canary
    - 25%    # Early adopters
    - 100%   # Everyone else
```

### Pattern 2: Blue-Green Deployment

```yaml
- hosts: blue_pool
  tasks:
    - name: Deploy to blue pool
      copy:
        src: app-v2.jar
        dest: /opt/app/

- hosts: loadbalancers
  tasks:
    - name: Switch traffic to blue pool
      command: lb-switch-to blue
```

### Pattern 3: Conditional Delegation

```yaml
- name: Delegate based on environment
  command: /opt/notify.sh
  delegate_to: "{{ monitoring_server[environment] }}"
```

---

## 📝 Summary

**Key Takeaways:**

1. **delegate_to** runs tasks on different hosts
2. **run_once** executes tasks once across all hosts
3. **serial** enables rolling updates with batch control
4. **local_action** runs tasks on control machine
5. **max_fail_percentage** controls failure tolerance
6. Combine patterns for zero-downtime deployments
7. Always validate and implement rollback strategies

**Common Use Cases:**

- ✅ Load balancer management during deployments
- ✅ Zero-downtime rolling updates
- ✅ Notification and monitoring integration
- ✅ Multi-tier orchestration
- ✅ Canary and blue-green deployments

**Next Steps:**

- Complete Lab 5: Rolling Updates
- Practice zero-downtime deployments
- Move on to Topic 6: Environment & Proxies

---

## 📖 Additional Resources

- [Delegation Documentation](https://docs.ansible.com/ansible/latest/user_guide/playbooks_delegation.html)
- [Rolling Updates Guide](https://docs.ansible.com/ansible/latest/user_guide/playbooks_strategies.html)
- [Error Handling](https://docs.ansible.com/ansible/latest/user_guide/playbooks_error_handling.html)

---

**Ready for hands-on practice? Head to `labs/lab5-rolling-updates.md`! 🚀**
