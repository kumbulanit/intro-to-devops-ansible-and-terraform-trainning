# 🔄 Topic 3: How to Differentiate Staging vs Production

## 🎯 Objective

Learn strategies and best practices for cleanly separating staging and production environments while maintaining code reusability and preventing cross-environment accidents.

---

## 📖 Why Environment Separation Matters

**Critical Reasons:**
- ✅ Prevents accidental production changes
- ✅ Enables safe testing before production deployment
- ✅ Allows different configurations per environment
- ✅ Supports gradual rollout strategies
- ✅ Maintains security and compliance requirements

**Common Environments:**
- **Development** - Local testing, rapid changes
- **Staging** - Pre-production testing, mirrors production
- **Production** - Live systems, strict change control
- **QA/Testing** - Quality assurance, automated testing

---

## 🏗️ Strategy 1: Separate Inventory Files (Recommended)

### Directory Structure

```plaintext
inventories/
├── production/
│   ├── hosts
│   ├── group_vars/
│   │   ├── all.yml
│   │   ├── webservers.yml
│   │   └── dbservers.yml
│   └── host_vars/
│       ├── web1.prod.example.com.yml
│       └── db1.prod.example.com.yml
└── staging/
    ├── hosts
    ├── group_vars/
    │   ├── all.yml
    │   ├── webservers.yml
    │   └── dbservers.yml
    └── host_vars/
        ├── web1.staging.example.com.yml
        └── db1.staging.example.com.yml
```

### Production Inventory

**`inventories/production/hosts`**

```ini
[webservers]
web1.prod.example.com ansible_host=10.0.1.10
web2.prod.example.com ansible_host=10.0.1.11

[dbservers]
db1.prod.example.com ansible_host=10.0.2.10

[loadbalancers]
lb1.prod.example.com ansible_host=10.0.3.10

[production:children]
webservers
dbservers
loadbalancers

[production:vars]
env=production
ansible_user=ansible
```

### Staging Inventory

**`inventories/staging/hosts`**

```ini
[webservers]
web1.staging.example.com ansible_host=10.1.1.10

[dbservers]
db1.staging.example.com ansible_host=10.1.2.10

[staging:children]
webservers
dbservers

[staging:vars]
env=staging
ansible_user=ansible
```

### Usage

```bash
# Deploy to staging
ansible-playbook -i inventories/staging site.yml

# Deploy to production
ansible-playbook -i inventories/production site.yml
```

---

## 🏗️ Strategy 2: Environment-Specific Variables

### Global Variables Structure

```plaintext
group_vars/
├── all/
│   ├── common.yml           # Common to all environments
│   └── vault.yml            # Encrypted secrets
├── production/
│   ├── vars.yml             # Production-specific
│   └── vault.yml            # Production secrets
└── staging/
    ├── vars.yml             # Staging-specific
    └── vault.yml            # Staging secrets
```

### Common Variables (All Environments)

**`inventories/production/group_vars/all.yml`**

```yaml
---
# Common settings across all hosts
ntp_servers:
  - 0.pool.ntp.org
  - 1.pool.ntp.org

monitoring_enabled: true

common_packages:
  - vim
  - git
  - htop
  - curl

log_retention_days: 30
```

### Production-Specific Variables

**`inventories/production/group_vars/all.yml`** (production-specific)

```yaml
---
environment: production
domain: example.com

# Production resource allocation
max_connections: 500
worker_processes: 4
memory_limit: 4096M

# Production URLs
api_url: https://api.example.com
db_host: db1.prod.example.com

# Backup configuration
backup_enabled: true
backup_schedule: "0 2 * * *"
backup_retention: 30

# Monitoring
monitoring_level: high
alert_email: ops@example.com

# Security
ssl_required: true
firewall_enabled: true
```

### Staging-Specific Variables

**`inventories/staging/group_vars/all.yml`** (staging-specific)

```yaml
---
environment: staging
domain: staging.example.com

# Staging resource allocation (lower)
max_connections: 100
worker_processes: 2
memory_limit: 2048M

# Staging URLs
api_url: https://api.staging.example.com
db_host: db1.staging.example.com

# Backup configuration (less frequent)
backup_enabled: true
backup_schedule: "0 3 * * 0"
backup_retention: 7

# Monitoring
monitoring_level: medium
alert_email: dev@example.com

# Security (more relaxed for testing)
ssl_required: false
firewall_enabled: true
```

---

## 🏗️ Strategy 3: Using Ansible Vault for Secrets

### Separate Vault Files Per Environment

#### Production Vault

```bash
# Create production vault
ansible-vault create inventories/production/group_vars/all/vault.yml
```

**Content:**

```yaml
---
vault_db_password: "Pr0d_S3cur3_P@ssw0rd"
vault_api_key: "prod-api-key-xyz123"
vault_ssl_cert_password: "prod-cert-pass"
```

#### Staging Vault

```bash
# Create staging vault
ansible-vault create inventories/staging/group_vars/all/vault.yml
```

**Content:**

```yaml
---
vault_db_password: "St@ging_P@ssw0rd"
vault_api_key: "staging-api-key-abc456"
vault_ssl_cert_password: "staging-cert-pass"
```

### Reference Vault Variables

**`inventories/production/group_vars/all.yml`**

```yaml
---
db_password: "{{ vault_db_password }}"
api_key: "{{ vault_api_key }}"
ssl_cert_password: "{{ vault_ssl_cert_password }}"
```

### Use Different Vault Passwords

```bash
# Store vault passwords separately
echo "production-vault-password" > .vault_pass_production
echo "staging-vault-password" > .vault_pass_staging

chmod 600 .vault_pass_*

# Add to .gitignore
echo ".vault_pass_*" >> .gitignore
```

### Run with Appropriate Vault Password

```bash
# Staging deployment
ansible-playbook -i inventories/staging site.yml --vault-password-file .vault_pass_staging

# Production deployment
ansible-playbook -i inventories/production site.yml --vault-password-file .vault_pass_production
```

---

## 🏗️ Strategy 4: Environment Detection in Playbooks

### Use Conditionals Based on Environment

```yaml
---
- name: Configure web servers
  hosts: webservers
  
  tasks:
    - name: Display environment
      debug:
        msg: "Deploying to {{ environment }}"
    
    - name: Install production monitoring (production only)
      apt:
        name: datadog-agent
        state: present
      when: environment == "production"
    
    - name: Enable debug logging (staging only)
      lineinfile:
        path: /etc/app/config.yml
        regexp: '^log_level:'
        line: 'log_level: debug'
      when: environment == "staging"
    
    - name: Configure resource limits
      template:
        src: app.conf.j2
        dest: /etc/app/app.conf
      vars:
        memory_limit: "{{ memory_limit }}"
        worker_processes: "{{ worker_processes }}"
```

### Template with Environment-Specific Values

**`templates/app.conf.j2`**

```jinja
# Application Configuration - {{ environment }}
{% if environment == "production" %}
# Production Configuration
max_connections = {{ max_connections }}
worker_processes = {{ worker_processes }}
log_level = warn
debug_mode = false
cache_enabled = true
{% else %}
# Staging/Development Configuration
max_connections = {{ max_connections }}
worker_processes = {{ worker_processes }}
log_level = debug
debug_mode = true
cache_enabled = false
{% endif %}

# Common Settings
domain = {{ domain }}
api_url = {{ api_url }}
db_host = {{ db_host }}
```

---

## 🏗️ Strategy 5: Safety Guards and Confirmation Prompts

### Require Confirmation for Production

**`site.yml`**

```yaml
---
- name: Safety check for production deployment
  hosts: localhost
  gather_facts: no
  
  tasks:
    - name: Pause for production confirmation
      pause:
        prompt: |
          
          ⚠️  WARNING: You are about to deploy to PRODUCTION!
          
          Environment: {{ hostvars[groups['all'][0]].environment | default('UNKNOWN') }}
          Inventory: {{ inventory_file }}
          
          Type 'yes' to continue or Ctrl+C to abort
      when: 
        - hostvars[groups['all'][0]].environment | default('') == 'production'
      register: confirmation
    
    - name: Verify confirmation
      assert:
        that:
          - confirmation.user_input | lower == 'yes'
        fail_msg: "Production deployment cancelled by user"
      when: 
        - hostvars[groups['all'][0]].environment | default('') == 'production'

- import_playbook: webservers.yml
- import_playbook: dbservers.yml
```

### Add Production Protection Flag

**`ansible.cfg`**

```ini
[defaults]
inventory = ./inventories/staging
ask_vault_pass = False

[production]
# Require explicit confirmation
ask_pass = True
ask_vault_pass = True
```

---

## 🏗️ Strategy 6: Wrapper Scripts for Deployment

### Staging Deployment Script

**`deploy-staging.sh`**

```bash
#!/bin/bash
set -e

ENVIRONMENT="staging"
INVENTORY="inventories/staging"
VAULT_PASS=".vault_pass_staging"

echo "================================================"
echo " Deploying to STAGING Environment"
echo "================================================"
echo ""

# Syntax check
echo "→ Checking playbook syntax..."
ansible-playbook -i "$INVENTORY" site.yml --syntax-check

# Dry run
echo ""
echo "→ Running dry-run..."
ansible-playbook -i "$INVENTORY" site.yml --check --vault-password-file "$VAULT_PASS"

# Prompt for confirmation
echo ""
read -p "Proceed with staging deployment? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo "Deployment cancelled"
    exit 1
fi

# Execute deployment
echo ""
echo "→ Deploying to staging..."
ansible-playbook -i "$INVENTORY" site.yml --vault-password-file "$VAULT_PASS"

echo ""
echo "✅ Staging deployment complete!"
```

### Production Deployment Script

**`deploy-production.sh`**

```bash
#!/bin/bash
set -e

ENVIRONMENT="production"
INVENTORY="inventories/production"
VAULT_PASS=".vault_pass_production"

echo "================================================"
echo " ⚠️  PRODUCTION DEPLOYMENT WARNING ⚠️"
echo "================================================"
echo ""
echo "You are about to deploy to PRODUCTION!"
echo "This will affect live systems and users."
echo ""

# Require explicit production flag
if [ "$1" != "--production" ]; then
    echo "ERROR: Must specify --production flag"
    echo "Usage: $0 --production"
    exit 1
fi

# Syntax check
echo "→ Checking playbook syntax..."
ansible-playbook -i "$INVENTORY" site.yml --syntax-check

# Dry run
echo ""
echo "→ Running dry-run..."
ansible-playbook -i "$INVENTORY" site.yml --check --vault-password-file "$VAULT_PASS"

# Double confirmation
echo ""
echo "⚠️  FINAL CONFIRMATION REQUIRED ⚠️"
read -p "Type 'DEPLOY TO PRODUCTION' to proceed: " CONFIRM
if [ "$CONFIRM" != "DEPLOY TO PRODUCTION" ]; then
    echo "Production deployment cancelled"
    exit 1
fi

# Log deployment
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
echo "$TIMESTAMP - Production deployment initiated by $(whoami)" >> deployment.log

# Execute deployment
echo ""
echo "→ Deploying to production..."
ansible-playbook -i "$INVENTORY" site.yml --vault-password-file "$VAULT_PASS"

# Log completion
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
echo "$TIMESTAMP - Production deployment completed" >> deployment.log

echo ""
echo "✅ Production deployment complete!"
echo "Logged to deployment.log"
```

### Make Scripts Executable

```bash
chmod +x deploy-staging.sh deploy-production.sh
```

### Usage

```bash
# Staging deployment (no special flag needed)
./deploy-staging.sh

# Production deployment (requires --production flag)
./deploy-production.sh --production
```

---

## 🛠️ Complete Hands-On Lab

### Lab Setup

```bash
mkdir -p ~/ansible-training/day5/env-separation-lab
cd ~/ansible-training/day5/env-separation-lab
```

### Step 1: Create Directory Structure

```bash
mkdir -p inventories/{production,staging}/{group_vars/all,host_vars}
mkdir -p roles/{common,webserver}/tasks
```

### Step 2: Create Inventories

**Production:**

```bash
cat > inventories/production/hosts << 'EOF'
[webservers]
web1.prod
web2.prod

[production:children]
webservers

[production:vars]
env=production
ansible_connection=local
EOF
```

**Staging:**

```bash
cat > inventories/staging/hosts << 'EOF'
[webservers]
web1.staging

[staging:children]
webservers

[staging:vars]
env=staging
ansible_connection=local
EOF
```

### Step 3: Create Environment-Specific Variables

**Production Variables:**

```bash
cat > inventories/production/group_vars/all/vars.yml << 'EOF'
---
environment: production
max_connections: 500
log_level: warn
backup_enabled: true
monitoring_url: https://monitoring.prod.example.com
EOF

# Create production vault
ansible-vault create inventories/production/group_vars/all/vault.yml
# Add: vault_db_password: "Prod_P@ss"
```

**Staging Variables:**

```bash
cat > inventories/staging/group_vars/all/vars.yml << 'EOF'
---
environment: staging
max_connections: 100
log_level: debug
backup_enabled: false
monitoring_url: https://monitoring.staging.example.com
EOF

# Create staging vault
ansible-vault create inventories/staging/group_vars/all/vault.yml
# Add: vault_db_password: "Staging_P@ss"
```

### Step 4: Create Playbook with Environment Logic

```bash
cat > site.yml << 'EOF'
---
- name: Environment-aware deployment
  hosts: all
  gather_facts: yes
  
  pre_tasks:
    - name: Display deployment information
      debug:
        msg: |
          Deploying to: {{ environment }}
          Max Connections: {{ max_connections }}
          Log Level: {{ log_level }}
          Backup: {{ backup_enabled }}
    
    - name: Production safety check
      pause:
        prompt: "⚠️  Press ENTER to deploy to PRODUCTION or Ctrl+C to abort"
      when: environment == "production"
  
  tasks:
    - name: Create app directory
      file:
        path: /tmp/myapp-{{ environment }}
        state: directory
    
    - name: Deploy configuration file
      copy:
        content: |
          Environment: {{ environment }}
          Max Connections: {{ max_connections }}
          Log Level: {{ log_level }}
          DB Password: {{ vault_db_password }}
        dest: /tmp/myapp-{{ environment }}/config.txt
    
    - name: Show deployment result
      debug:
        msg: "✅ Deployed to {{ environment }} successfully!"
EOF
```

### Step 5: Test Both Environments

```bash
# Test staging (should work without prompts)
ansible-playbook -i inventories/staging site.yml --ask-vault-pass

# Test production (should prompt for confirmation)
ansible-playbook -i inventories/production site.yml --ask-vault-pass

# Verify files created
ls -la /tmp/myapp-*
cat /tmp/myapp-staging/config.txt
cat /tmp/myapp-production/config.txt
```

---

## 💡 Best Practices Summary

1. **Always Use Separate Inventories**
   - Never mix production and staging in the same inventory
   - Use clear naming conventions

2. **Different Vault Passwords**
   - Production and staging should have different vault passwords
   - Store vault passwords securely (password managers, secrets management)

3. **Require Explicit Production Flag**
   - Use wrapper scripts with special flags for production
   - Implement confirmation prompts

4. **Test in Staging First**
   - Always deploy to staging before production
   - Use identical configurations where possible

5. **Use Version Control**
   - Track all inventory and variable changes
   - Use branches for environment-specific changes

6. **Audit and Logging**
   - Log all production deployments
   - Track who deployed what and when

7. **Implement Rollback Procedures**
   - Have a tested rollback plan
   - Keep previous versions accessible

8. **Use CI/CD Pipelines**
   - Automate staging deployments
   - Require manual approval for production

---

## ✅ Checklist

- [ ] Created separate inventory directories
- [ ] Configured environment-specific variables
- [ ] Set up separate vault files with different passwords
- [ ] Implemented production safety guards
- [ ] Created deployment wrapper scripts
- [ ] Tested staging deployment
- [ ] Tested production deployment (with safeguards)
- [ ] Documented environment differences
- [ ] Set up logging for production deployments

---

## 🔗 Next Steps

Continue to **Topic 4: Group and Host Variables** to master variable precedence and organization.
