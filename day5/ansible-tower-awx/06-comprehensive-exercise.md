# 🎯 Comprehensive Exercise: AWX + Jenkins + GitHub + OpenStack

## 📖 Overview

This comprehensive exercise combines all concepts from Day 5:
- AWX/Jenkins automation
- GitHub integration
- OpenStack infrastructure
- Best practices implementation

**Time:** 3-4 hours

**Difficulty:** Advanced

---

## 🎯 Exercise Objectives

Deploy a complete three-tier web application using:
1. **OpenStack:** Provision infrastructure
2. **GitHub:** Store playbooks and code
3. **AWX:** Orchestrate deployments
4. **Jenkins:** CI/CD pipeline (optional)

### Application Architecture

```plaintext
                    ┌─────────────────┐
                    │   GitHub Repo   │
                    │   (Playbooks)   │
                    └────────┬────────┘
                             │
              ┌──────────────┴──────────────┐
              │                             │
    ┌─────────▼────────┐        ┌──────────▼─────────┐
    │   Jenkins        │        │      AWX           │
    │   (CI/CD)        │        │  (Orchestration)   │
    └─────────┬────────┘        └──────────┬─────────┘
              │                             │
              └──────────────┬──────────────┘
                             │
                   ┌─────────▼──────────┐
                   │    OpenStack       │
                   └─────────┬──────────┘
                             │
         ┌───────────────────┼───────────────────┐
         │                   │                   │
  ┌──────▼──────┐    ┌──────▼──────┐    ┌──────▼──────┐
  │   HAProxy   │    │   Nginx x2  │    │ PostgreSQL  │
  │ (LB Layer)  │───▶│ (Web Layer) │───▶│  (DB Layer) │
  └─────────────┘    └─────────────┘    └─────────────┘
```

---

## 📋 Prerequisites

- [ ] OpenStack environment accessible
- [ ] GitHub account
- [ ] AWX installed (local or OpenStack)
- [ ] SSH key pair created
- [ ] `openstacksdk` installed
- [ ] Ansible 2.9+ installed

---

## 🚀 Part 1: Setup GitHub Repository

### Step 1: Create Repository

```bash
# Create repository structure
mkdir ansible-webapp-deployment
cd ansible-webapp-deployment

# Initialize git
git init

# Create directory structure
mkdir -p {playbooks,roles,inventories/{production,staging},group_vars,host_vars,files,templates}
```

### Step 2: Create OpenStack Configuration

**File:** `clouds.yaml`

```yaml
---
clouds:
  myopenstack:
    auth:
      auth_url: http://YOUR_OPENSTACK_IP/identity
      username: admin
      password: your_password
      project_name: admin
      project_domain_name: Default
      user_domain_name: Default
    region_name: RegionOne
    interface: public
    identity_api_version: 3
```

**File:** `.gitignore`

```
# Sensitive files
clouds.yaml
*.pem
*.key
vault_password.txt
.vault_pass

# Ansible
*.retry
.ansible/

# Python
__pycache__/
*.pyc
```

### Step 3: Create Infrastructure Playbook

**File:** `playbooks/01-provision-infrastructure.yml`

```yaml
---
- name: Provision Three-Tier Infrastructure on OpenStack
  hosts: localhost
  gather_facts: no
  vars:
    cloud_name: myopenstack
    key_name: webapp-key
    network_name: private
    
    # Security groups
    security_groups:
      - name: lb-sg
        description: Load balancer security group
        rules:
          - { protocol: tcp, port: 22, cidr: '0.0.0.0/0' }
          - { protocol: tcp, port: 80, cidr: '0.0.0.0/0' }
          - { protocol: tcp, port: 443, cidr: '0.0.0.0/0' }
      
      - name: web-sg
        description: Web server security group
        rules:
          - { protocol: tcp, port: 22, cidr: '0.0.0.0/0' }
          - { protocol: tcp, port: 80, cidr: '10.0.0.0/24' }
          - { protocol: tcp, port: 443, cidr: '10.0.0.0/24' }
      
      - name: db-sg
        description: Database security group
        rules:
          - { protocol: tcp, port: 22, cidr: '0.0.0.0/0' }
          - { protocol: tcp, port: 5432, cidr: '10.0.0.0/24' }
    
    # Instances
    instances:
      - name: haproxy-lb
        flavor: m1.small
        image: ubuntu-22.04
        security_groups: [lb-sg, default]
        metadata: { tier: loadbalancer, environment: production, application: webapp }
        floating_ip: yes
      
      - name: web-server-1
        flavor: m1.medium
        image: ubuntu-22.04
        security_groups: [web-sg, default]
        metadata: { tier: webserver, environment: production, application: webapp }
        floating_ip: no
      
      - name: web-server-2
        flavor: m1.medium
        image: ubuntu-22.04
        security_groups: [web-sg, default]
        metadata: { tier: webserver, environment: production, application: webapp }
        floating_ip: no
      
      - name: postgresql-db
        flavor: m1.large
        image: ubuntu-22.04
        security_groups: [db-sg, default]
        metadata: { tier: database, environment: production, application: webapp }
        floating_ip: no

  tasks:
    - name: Create security groups
      openstack.cloud.security_group:
        cloud: "{{ cloud_name }}"
        name: "{{ item.name }}"
        description: "{{ item.description }}"
        state: present
      loop: "{{ security_groups }}"

    - name: Add security group rules
      openstack.cloud.security_group_rule:
        cloud: "{{ cloud_name }}"
        security_group: "{{ item.0.name }}"
        protocol: "{{ item.1.protocol }}"
        port_range_min: "{{ item.1.port }}"
        port_range_max: "{{ item.1.port }}"
        remote_ip_prefix: "{{ item.1.cidr }}"
        state: present
      with_subelements:
        - "{{ security_groups }}"
        - rules
      ignore_errors: yes

    - name: Create SSH keypair
      openstack.cloud.keypair:
        cloud: "{{ cloud_name }}"
        name: "{{ key_name }}"
        public_key_file: ~/.ssh/id_rsa.pub
        state: present

    - name: Launch instances
      openstack.cloud.server:
        cloud: "{{ cloud_name }}"
        name: "{{ item.name }}"
        flavor: "{{ item.flavor }}"
        image: "{{ item.image }}"
        key_name: "{{ key_name }}"
        network: "{{ network_name }}"
        security_groups: "{{ item.security_groups }}"
        auto_ip: "{{ item.floating_ip }}"
        meta: "{{ item.metadata }}"
        wait: yes
        timeout: 600
        state: present
      loop: "{{ instances }}"
      register: launched_instances

    - name: Display instance information
      debug:
        msg: |
          Instance: {{ item.server.name }}
          ID: {{ item.server.id }}
          Private IP: {{ item.server.private_v4 }}
          Public IP: {{ item.server.public_v4 | default('N/A') }}
      loop: "{{ launched_instances.results }}"

    - name: Save inventory file
      copy:
        content: |
          [loadbalancers]
          {% for instance in launched_instances.results %}
          {% if instance.server.metadata.tier == 'loadbalancer' %}
          {{ instance.server.name }} ansible_host={{ instance.server.public_v4 }} private_ip={{ instance.server.private_v4 }}
          {% endif %}
          {% endfor %}
          
          [webservers]
          {% for instance in launched_instances.results %}
          {% if instance.server.metadata.tier == 'webserver' %}
          {{ instance.server.name }} ansible_host={{ instance.server.private_v4 }}
          {% endif %}
          {% endfor %}
          
          [databases]
          {% for instance in launched_instances.results %}
          {% if instance.server.metadata.tier == 'database' %}
          {{ instance.server.name }} ansible_host={{ instance.server.private_v4 }}
          {% endif %}
          {% endfor %}
          
          [all:vars]
          ansible_user=ubuntu
          ansible_ssh_private_key_file=~/.ssh/id_rsa
          ansible_python_interpreter=/usr/bin/python3
        dest: ./inventories/production/hosts

    - name: Wait for SSH on instances
      wait_for:
        host: "{{ item.server.public_v4 | default(item.server.private_v4) }}"
        port: 22
        delay: 10
        timeout: 300
      loop: "{{ launched_instances.results }}"
      when: item.server.public_v4 is defined
```

### Step 4: Create Configuration Playbooks

**File:** `playbooks/02-configure-database.yml`

```yaml
---
- name: Configure PostgreSQL Database Server
  hosts: databases
  become: yes
  vars:
    postgres_version: 14
    db_name: webapp_db
    db_user: webapp_user
    db_password: "{{ vault_db_password }}"

  tasks:
    - name: Install PostgreSQL
      apt:
        name:
          - postgresql-{{ postgres_version }}
          - postgresql-contrib-{{ postgres_version }}
          - python3-psycopg2
        state: present
        update_cache: yes

    - name: Ensure PostgreSQL is running
      systemd:
        name: postgresql
        state: started
        enabled: yes

    - name: Configure PostgreSQL to listen on all interfaces
      lineinfile:
        path: /etc/postgresql/{{ postgres_version }}/main/postgresql.conf
        regexp: '^#?listen_addresses'
        line: "listen_addresses = '*'"
      notify: restart postgresql

    - name: Configure PostgreSQL authentication
      lineinfile:
        path: /etc/postgresql/{{ postgres_version }}/main/pg_hba.conf
        line: "host    all             all             10.0.0.0/24            md5"
      notify: restart postgresql

    - name: Create database
      become_user: postgres
      postgresql_db:
        name: "{{ db_name }}"
        state: present

    - name: Create database user
      become_user: postgres
      postgresql_user:
        name: "{{ db_user }}"
        password: "{{ db_password }}"
        db: "{{ db_name }}"
        priv: ALL
        state: present

  handlers:
    - name: restart postgresql
      systemd:
        name: postgresql
        state: restarted
```

**File:** `playbooks/03-configure-webservers.yml`

```yaml
---
- name: Configure Nginx Web Servers
  hosts: webservers
  become: yes
  vars:
    app_port: 80
    db_host: "{{ hostvars[groups['databases'][0]]['ansible_host'] }}"
    db_name: webapp_db
    db_user: webapp_user
    db_password: "{{ vault_db_password }}"

  tasks:
    - name: Install Nginx and PHP
      apt:
        name:
          - nginx
          - php-fpm
          - php-pgsql
          - php-json
        state: present
        update_cache: yes

    - name: Create web application directory
      file:
        path: /var/www/webapp
        state: directory
        owner: www-data
        group: www-data
        mode: '0755'

    - name: Deploy application code
      copy:
        content: |
          <?php
          $host = "{{ db_host }}";
          $dbname = "{{ db_name }}";
          $user = "{{ db_user }}";
          $password = "{{ db_password }}";
          
          try {
              $pdo = new PDO("pgsql:host=$host;dbname=$dbname", $user, $password);
              $status = "✅ Connected to database successfully";
              $color = "green";
          } catch (PDOException $e) {
              $status = "❌ Database connection failed: " . $e->getMessage();
              $color = "red";
          }
          ?>
          <!DOCTYPE html>
          <html>
          <head>
              <title>Web Application</title>
              <style>
                  body { font-family: Arial; margin: 50px; }
                  .status { color: <?php echo $color; ?>; font-weight: bold; }
              </style>
          </head>
          <body>
              <h1>Three-Tier Web Application</h1>
              <p><strong>Server:</strong> <?php echo gethostname(); ?></p>
              <p><strong>Server IP:</strong> <?php echo $_SERVER['SERVER_ADDR']; ?></p>
              <p class="status"><?php echo $status; ?></p>
              <p><strong>Database Host:</strong> {{ db_host }}</p>
              <p><strong>Timestamp:</strong> <?php echo date('Y-m-d H:i:s'); ?></p>
          </body>
          </html>
        dest: /var/www/webapp/index.php
        owner: www-data
        group: www-data
        mode: '0644'

    - name: Configure Nginx virtual host
      copy:
        content: |
          server {
              listen 80;
              server_name _;
              root /var/www/webapp;
              index index.php index.html;
              
              location / {
                  try_files $uri $uri/ =404;
              }
              
              location ~ \.php$ {
                  include snippets/fastcgi-php.conf;
                  fastcgi_pass unix:/var/run/php/php-fpm.sock;
              }
              
              location = /health {
                  access_log off;
                  return 200 "OK\n";
                  add_header Content-Type text/plain;
              }
          }
        dest: /etc/nginx/sites-available/webapp
      notify: restart nginx

    - name: Enable virtual host
      file:
        src: /etc/nginx/sites-available/webapp
        dest: /etc/nginx/sites-enabled/webapp
        state: link
      notify: restart nginx

    - name: Disable default site
      file:
        path: /etc/nginx/sites-enabled/default
        state: absent
      notify: restart nginx

    - name: Ensure Nginx is running
      systemd:
        name: nginx
        state: started
        enabled: yes

  handlers:
    - name: restart nginx
      systemd:
        name: nginx
        state: restarted
```

**File:** `playbooks/04-configure-loadbalancer.yml`

```yaml
---
- name: Configure HAProxy Load Balancer
  hosts: loadbalancers
  become: yes
  vars:
    web_servers: "{{ groups['webservers'] }}"

  tasks:
    - name: Install HAProxy
      apt:
        name: haproxy
        state: present
        update_cache: yes

    - name: Configure HAProxy
      template:
        src: ../templates/haproxy.cfg.j2
        dest: /etc/haproxy/haproxy.cfg
        validate: haproxy -f %s -c
      notify: restart haproxy

    - name: Ensure HAProxy is running
      systemd:
        name: haproxy
        state: started
        enabled: yes

  handlers:
    - name: restart haproxy
      systemd:
        name: haproxy
        state: restarted
```

**File:** `templates/haproxy.cfg.j2`

```jinja2
global
    log /dev/log local0
    log /dev/log local1 notice
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin
    stats timeout 30s
    user haproxy
    group haproxy
    daemon

defaults
    log     global
    mode    http
    option  httplog
    option  dontlognull
    timeout connect 5000
    timeout client  50000
    timeout server  50000

listen stats
    bind *:8404
    stats enable
    stats uri /stats
    stats refresh 30s
    stats admin if TRUE

frontend http_front
    bind *:80
    default_backend http_back

backend http_back
    balance roundrobin
    option httpchk GET /health
    http-check expect status 200
{% for host in groups['webservers'] %}
    server {{ host }} {{ hostvars[host]['ansible_host'] }}:80 check
{% endfor %}
```

**File:** `playbooks/site.yml`

```yaml
---
- import_playbook: 01-provision-infrastructure.yml
- import_playbook: 02-configure-database.yml
- import_playbook: 03-configure-webservers.yml
- import_playbook: 04-configure-loadbalancer.yml
```

### Step 5: Create Vault Variables

```bash
# Create vault file
ansible-vault create group_vars/all/vault.yml

# Add content:
---
vault_db_password: SuperSecureDBPassword123!

# Save vault password
echo "YourVaultPassword" > vault_password.txt
chmod 600 vault_password.txt
```

### Step 6: Push to GitHub

```bash
# Add all files
git add .

# Commit
git commit -m "Initial commit: Three-tier web application deployment"

# Add remote
git remote add origin https://github.com/YOUR_USERNAME/ansible-webapp-deployment.git

# Push
git push -u origin main
```

---

## 🔧 Part 2: Configure AWX

### Step 1: Add Credentials

#### OpenStack Credential

**AWX UI → Credentials → Add:**

```yaml
Name: My OpenStack
Credential Type: OpenStack
Host (Auth URL): http://YOUR_OPENSTACK_IP/identity
Username: admin
Password: your_password
Project Name: admin
Project Domain Name: Default
User Domain Name: Default
```

#### SSH Credential

```yaml
Name: SSH Key
Credential Type: Machine
Username: ubuntu
SSH Private Key: [Paste your private key]
```

#### GitHub Credential

```yaml
Name: GitHub Token
Credential Type: Source Control
Username: your_github_username
Password: your_personal_access_token
```

#### Vault Credential

```yaml
Name: Ansible Vault Password
Credential Type: Vault
Vault Password: YourVaultPassword
```

### Step 2: Create Project

**AWX UI → Projects → Add:**

```yaml
Name: WebApp Deployment Project
Organization: Default
SCM Type: Git
SCM URL: https://github.com/YOUR_USERNAME/ansible-webapp-deployment.git
SCM Credential: GitHub Token
SCM Update Options:
  ✅ Clean
  ✅ Delete on Update
  ✅ Update Revision on Launch
```

Click **Sync** to pull the repository.

### Step 3: Create Inventory

**AWX UI → Inventories → Add:**

```yaml
Name: WebApp Infrastructure
Organization: Default
```

**Add Source:**

```yaml
Name: OpenStack VMs
Source: OpenStack
Credential: My OpenStack
Source Variables:
---
expand_hostvars: yes
compose:
  ansible_host: private_v4
  ansible_user: ubuntu
groups:
  loadbalancers: "metadata.tier == 'loadbalancer'"
  webservers: "metadata.tier == 'webserver'"
  databases: "metadata.tier == 'database'"
Update Options:
  ✅ Overwrite
  ✅ Update on Launch
```

### Step 4: Create Job Templates

#### Template 1: Full Deployment

**AWX UI → Templates → Add Job Template:**

```yaml
Name: Deploy Complete WebApp Stack
Job Type: Run
Inventory: WebApp Infrastructure
Project: WebApp Deployment Project
Playbook: playbooks/site.yml
Credentials:
  - My OpenStack
  - SSH Key
  - Ansible Vault Password
Options:
  ✅ Prompt on Launch (Extra Variables)
  ✅ Enable Webhook
  ✅ Enable Concurrent Jobs
```

#### Template 2: Update Web Tier Only

```yaml
Name: Update Web Tier
Job Type: Run
Inventory: WebApp Infrastructure
Project: WebApp Deployment Project
Playbook: playbooks/03-configure-webservers.yml
Credentials:
  - SSH Key
  - Ansible Vault Password
Limit: webservers
```

#### Template 3: Provision Infrastructure Only

```yaml
Name: Provision Infrastructure
Job Type: Run
Inventory: localhost
Project: WebApp Deployment Project
Playbook: playbooks/01-provision-infrastructure.yml
Credentials:
  - My OpenStack
```

### Step 5: Create Workflow

**AWX UI → Templates → Add Workflow Template:**

```yaml
Name: Complete WebApp Deployment Workflow
Organization: Default
Inventory: WebApp Infrastructure
```

**Workflow Visualizer:**

```
START
  ↓
[Provision Infrastructure]
  ↓ (on success)
[Sync Inventory]
  ↓ (on success)
  ├─→ [Configure Database]
  │     ↓ (on success)
  ├─→ [Configure Web Servers] ← (wait for DB)
  │     ↓ (on success)
  └─→ [Configure Load Balancer] ← (wait for Web)
        ↓ (on success)
      [END]
```

---

## 🔗 Part 3: Jenkins Integration (Optional)

### Create Jenkinsfile

**File:** `Jenkinsfile`

```groovy
pipeline {
    agent any
    
    environment {
        AWX_URL = 'http://YOUR_AWX_IP:8080'
        AWX_TOKEN = credentials('awx-api-token')
        JOB_TEMPLATE_ID = '1'  // ID of "Deploy Complete WebApp Stack"
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Validate Playbooks') {
            steps {
                sh '''
                    find playbooks -name "*.yml" -exec ansible-playbook --syntax-check {} \\;
                '''
            }
        }
        
        stage('Trigger AWX Deployment') {
            steps {
                script {
                    def response = sh(
                        script: """
                            curl -X POST ${AWX_URL}/api/v2/job_templates/${JOB_TEMPLATE_ID}/launch/ \\
                                -H "Authorization: Bearer ${AWX_TOKEN}" \\
                                -H "Content-Type: application/json" \\
                                -d '{}'
                        """,
                        returnStdout: true
                    ).trim()
                    
                    echo "AWX Job Response: ${response}"
                }
            }
        }
    }
    
    post {
        success {
            echo '✅ Deployment triggered successfully!'
        }
        failure {
            echo '❌ Deployment failed!'
        }
    }
}
```

---

## ✅ Part 4: Testing

### Test 1: Manual Deployment via Ansible

```bash
# Test provision playbook
ansible-playbook playbooks/01-provision-infrastructure.yml \
    --vault-password-file=vault_password.txt

# Wait for VMs to be ready

# Test full deployment
ansible-playbook playbooks/site.yml \
    -i inventories/production/hosts \
    --vault-password-file=vault_password.txt
```

### Test 2: AWX Deployment

1. **AWX UI → Templates → Deploy Complete WebApp Stack**
2. Click **Launch**
3. Monitor job output
4. Verify success

### Test 3: Access Application

```bash
# Get load balancer IP
openstack server show haproxy-lb -f value -c addresses

# Test application
curl http://LOAD_BALANCER_IP/

# Check HAProxy stats
curl http://LOAD_BALANCER_IP:8404/stats
```

### Test 4: Verify Database Connection

```bash
# SSH to web server
ssh ubuntu@WEB_SERVER_IP

# Test database connection
php -r "
\$pdo = new PDO('pgsql:host=DB_IP;dbname=webapp_db', 'webapp_user', 'PASSWORD');
echo 'Connected successfully';
"
```

---

## 🎓 Expected Outcomes

After completing this exercise, you should have:

- ✅ GitHub repository with complete Ansible project
- ✅ OpenStack infrastructure (1 LB + 2 Web + 1 DB)
- ✅ AWX job templates for deployment
- ✅ Working three-tier web application
- ✅ HAProxy load balancing between web servers
- ✅ PostgreSQL database with web app connection
- ✅ Automated deployment workflow
- ✅ GitHub webhook integration (optional)
- ✅ Jenkins CI/CD pipeline (optional)

---

## 🏆 Bonus Challenges

1. **Add Monitoring:**
   - Install Prometheus on a new VM
   - Configure node exporters on all servers
   - Create Grafana dashboard

2. **Implement SSL:**
   - Generate Let's Encrypt certificates
   - Configure HTTPS on HAProxy
   - Redirect HTTP to HTTPS

3. **Add Auto-scaling:**
   - Create Ansible playbook to add/remove web servers
   - Update HAProxy configuration dynamically
   - Trigger based on load

4. **Disaster Recovery:**
   - Create backup playbook for database
   - Implement restore procedure
   - Test recovery process

5. **Multi-Environment:**
   - Deploy staging environment
   - Implement blue-green deployment
   - Create promotion workflow

---

## 📚 Resources

- AWX API Documentation: https://docs.ansible.com/ansible-tower/latest/html/towerapi/
- OpenStack Ansible Modules: https://docs.ansible.com/ansible/latest/collections/openstack/cloud/
- HAProxy Documentation: http://www.haproxy.org/#docs
- Jenkins Pipeline Syntax: https://www.jenkins.io/doc/book/pipeline/syntax/

---

## 🎉 Conclusion

Congratulations! You've completed a comprehensive exercise covering:
- Infrastructure as Code with Ansible
- Cloud automation with OpenStack
- CI/CD with AWX and Jenkins
- GitOps workflows
- Enterprise best practices

This exercise demonstrates real-world DevOps practices used in production environments.
