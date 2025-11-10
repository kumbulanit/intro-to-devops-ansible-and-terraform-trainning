# 🌐 Topic 2: Use Dynamic Inventory With Clouds

## 🎯 Objective

Learn how to use dynamic inventory to automatically discover and manage hosts from cloud providers like AWS, Azure, OpenStack, and Google Cloud.

---

## 📖 What is Dynamic Inventory?

Dynamic inventory allows Ansible to query external systems (cloud providers, CMDBs, etc.) for host information instead of maintaining static inventory files.

**Benefits:**
- ✅ Automatically discovers new instances
- ✅ Always up-to-date inventory
- ✅ No manual inventory management
- ✅ Integrates with auto-scaling groups
- ✅ Supports multiple cloud providers

---

## 🔧 Dynamic Inventory Methods

### 1. Inventory Plugins (Recommended - Ansible 2.4+)
Modern, built-in inventory plugins for cloud providers.

### 2. Inventory Scripts (Legacy)
Python/shell scripts that return JSON inventory.

---

## ☁️ Cloud Provider Examples

### **AWS EC2 Dynamic Inventory**

#### Step 1: Install Required Collection

```bash
ansible-galaxy collection install amazon.aws
pip3 install boto3 botocore
```

#### Step 2: Configure AWS Credentials

```bash
# ~/.aws/credentials
[default]
aws_access_key_id = YOUR_ACCESS_KEY
aws_secret_access_key = YOUR_SECRET_KEY
region = us-east-1
```

#### Step 3: Create Inventory Plugin Configuration

Create `inventories/aws_ec2.yml`:

```yaml
---
plugin: amazon.aws.aws_ec2

regions:
  - us-east-1
  - us-west-2

filters:
  instance-state-name: running
  tag:Environment:
    - production
    - staging

keyed_groups:
  # Create groups based on tags
  - key: tags.Environment
    prefix: env
  - key: tags.Application
    prefix: app
  - key: placement.availability_zone
    prefix: az
  - key: instance_type
    prefix: instance_type

hostnames:
  # Use private IP as hostname
  - ip-address
  
compose:
  ansible_host: public_ip_address
  ansible_user: "'ec2-user'"
```

#### Step 4: Test the Dynamic Inventory

```bash
# List all hosts discovered
ansible-inventory -i inventories/aws_ec2.yml --list

# View inventory graph
ansible-inventory -i inventories/aws_ec2.yml --graph

# Ping all EC2 instances
ansible all -i inventories/aws_ec2.yml -m ping
```

#### Step 5: Use in Playbooks

```yaml
---
- name: Configure AWS EC2 instances
  hosts: env_production
  gather_facts: yes
  
  tasks:
    - name: Display instance information
      debug:
        msg: "Instance {{ inventory_hostname }} in {{ placement.availability_zone }}"
    
    - name: Install nginx on web servers
      apt:
        name: nginx
        state: present
      when: "'app_web' in group_names"
```

---

### **Azure Dynamic Inventory**

#### Step 1: Install Requirements

```bash
ansible-galaxy collection install azure.azcollection
pip3 install -r ~/.ansible/collections/ansible_collections/azure/azcollection/requirements-azure.txt
```

#### Step 2: Configure Azure Credentials

Create `~/.azure/credentials`:

```ini
[default]
subscription_id=YOUR_SUBSCRIPTION_ID
client_id=YOUR_CLIENT_ID
secret=YOUR_SECRET
tenant=YOUR_TENANT_ID
```

Or use environment variables:

```bash
export AZURE_SUBSCRIPTION_ID=YOUR_SUBSCRIPTION_ID
export AZURE_CLIENT_ID=YOUR_CLIENT_ID
export AZURE_SECRET=YOUR_SECRET
export AZURE_TENANT=YOUR_TENANT_ID
```

#### Step 3: Create Azure Inventory Configuration

Create `inventories/azure_rm.yml`:

```yaml
---
plugin: azure.azcollection.azure_rm

auth_source: auto
include_vm_resource_groups:
  - production-rg
  - staging-rg

exclude_host_filters:
  - powerstate != 'running'

keyed_groups:
  - prefix: tag
    key: tags
  - prefix: azure_loc
    key: location
  - prefix: azure_os
    key: os_profile.system

hostnames:
  - name
  - public_ipv4_addresses

compose:
  ansible_host: public_ipv4_addresses[0]
  ansible_user: "'azureuser'"
```

#### Step 4: Test Azure Inventory

```bash
# List Azure VMs
ansible-inventory -i inventories/azure_rm.yml --list

# Ping all Azure VMs
ansible all -i inventories/azure_rm.yml -m ping
```

---

### **OpenStack Dynamic Inventory**

#### Step 1: Install Requirements

```bash
ansible-galaxy collection install openstack.cloud
pip3 install openstacksdk
```

#### Step 2: Configure OpenStack Credentials

Create `~/.config/openstack/clouds.yaml`:

```yaml
clouds:
  devstack:
    auth:
      auth_url: http://controller:5000/v3
      username: admin
      password: secret
      project_name: admin
      user_domain_name: Default
      project_domain_name: Default
    region_name: RegionOne
    interface: public
```

#### Step 3: Create OpenStack Inventory Configuration

Create `inventories/openstack.yml`:

```yaml
---
plugin: openstack.cloud.openstack

clouds:
  - devstack

expand_hostvars: yes
fail_on_errors: yes

keyed_groups:
  - key: metadata.environment
    prefix: env
  - key: metadata.role
    prefix: role

compose:
  ansible_host: accessIPv4
  ansible_user: "'ubuntu'"
```

#### Step 4: Use OpenStack Inventory

```bash
# List OpenStack instances
ansible-inventory -i inventories/openstack.yml --list

# Run against specific groups
ansible env_production -i inventories/openstack.yml -m ping
```

---

### **Google Cloud Platform (GCP) Dynamic Inventory**

#### Step 1: Install Requirements

```bash
ansible-galaxy collection install google.cloud
pip3 install requests google-auth
```

#### Step 2: Configure GCP Credentials

```bash
# Download service account JSON key
# Set environment variable
export GCP_SERVICE_ACCOUNT_FILE=~/gcp-service-account.json
```

#### Step 3: Create GCP Inventory Configuration

Create `inventories/gcp_compute.yml`:

```yaml
---
plugin: google.cloud.gcp_compute

projects:
  - my-gcp-project

zones:
  - us-central1-a
  - us-central1-b

filters:
  - status = RUNNING
  - labels.environment = production OR labels.environment = staging

keyed_groups:
  - key: labels.environment
    prefix: env
  - key: labels.role
    prefix: role
  - key: zone
    prefix: zone

hostnames:
  - name
  - public_ip

compose:
  ansible_host: networkInterfaces[0].accessConfigs[0].natIP
  ansible_user: "'gcp-user'"
```

---

## 🔄 Multi-Cloud Dynamic Inventory

### Combining Multiple Cloud Providers

Create `inventories/multi-cloud/` directory:

```bash
inventories/multi-cloud/
├── aws_ec2.yml
├── azure_rm.yml
├── openstack.yml
└── gcp_compute.yml
```

Use all inventories:

```bash
ansible-playbook -i inventories/multi-cloud/ site.yml
```

---

## 🛠️ Hands-On Lab: OpenStack Dynamic Inventory

### Complete Working Example

#### Step 1: Setup Directory Structure

```bash
mkdir -p ~/ansible-training/day5/dynamic-inventory-lab/{inventories,playbooks,group_vars}
cd ~/ansible-training/day5/dynamic-inventory-lab
```

#### Step 2: Configure OpenStack Cloud

```bash
mkdir -p ~/.config/openstack

cat > ~/.config/openstack/clouds.yaml << 'EOF'
clouds:
  devstack:
    auth:
      auth_url: http://10.0.3.15/identity
      username: admin
      password: devstack
      project_name: admin
      user_domain_name: Default
      project_domain_name: Default
    region_name: RegionOne
    interface: public
    identity_api_version: 3
EOF
```

#### Step 3: Create Dynamic Inventory Configuration

```bash
cat > inventories/openstack.yml << 'EOF'
---
plugin: openstack.cloud.openstack

clouds:
  - devstack

expand_hostvars: yes
fail_on_errors: no

# Group instances by metadata tags
keyed_groups:
  - key: metadata.environment
    prefix: env
    separator: "_"
  - key: metadata.role
    prefix: role
    separator: "_"
  - key: metadata.application
    prefix: app
    separator: "_"

# Define how to connect to instances
compose:
  ansible_host: public_v4
  ansible_user: "'ubuntu'"
  ansible_ssh_private_key_file: "'~/.ssh/id_rsa'"

# Additional host variables
hostvar_expressions:
  environment: metadata.environment | default('unknown')
  role: metadata.role | default('unknown')
  application: metadata.application | default('unknown')
EOF
```

#### Step 4: Create OpenStack Instances with Metadata

```bash
cat > playbooks/provision_instances.yml << 'EOF'
---
- name: Provision OpenStack instances with metadata
  hosts: localhost
  gather_facts: no
  
  vars:
    cloud_name: devstack
    instances:
      - name: web-prod-01
        image: ubuntu
        flavor: m1.small
        network: private
        metadata:
          environment: production
          role: webserver
          application: ecommerce
      
      - name: web-prod-02
        image: ubuntu
        flavor: m1.small
        network: private
        metadata:
          environment: production
          role: webserver
          application: ecommerce
      
      - name: db-prod-01
        image: ubuntu
        flavor: m1.medium
        network: private
        metadata:
          environment: production
          role: database
          application: ecommerce
      
      - name: web-staging-01
        image: ubuntu
        flavor: m1.small
        network: private
        metadata:
          environment: staging
          role: webserver
          application: ecommerce
  
  tasks:
    - name: Create instances
      openstack.cloud.server:
        cloud: "{{ cloud_name }}"
        name: "{{ item.name }}"
        image: "{{ item.image }}"
        flavor: "{{ item.flavor }}"
        network: "{{ item.network }}"
        key_name: demo-key
        meta: "{{ item.metadata }}"
        auto_ip: yes
        wait: yes
      loop: "{{ instances }}"
EOF
```

#### Step 5: Provision Instances

```bash
ansible-playbook playbooks/provision_instances.yml
```

#### Step 6: Test Dynamic Inventory

```bash
# List all discovered hosts
ansible-inventory -i inventories/openstack.yml --list

# Show inventory graph
ansible-inventory -i inventories/openstack.yml --graph

# Output should look like:
# @all:
#   |--@env_production:
#   |  |--web-prod-01
#   |  |--web-prod-02
#   |  |--db-prod-01
#   |--@env_staging:
#   |  |--web-staging-01
#   |--@role_webserver:
#   |  |--web-prod-01
#   |  |--web-prod-02
#   |  |--web-staging-01
#   |--@role_database:
#   |  |--db-prod-01
```

#### Step 7: Create Environment-Specific Variables

```bash
# Production variables
cat > group_vars/env_production.yml << 'EOF'
---
environment: production
log_level: warn
monitoring_enabled: true
backup_schedule: "0 2 * * *"
EOF

# Staging variables
cat > group_vars/env_staging.yml << 'EOF'
---
environment: staging
log_level: debug
monitoring_enabled: false
backup_schedule: "0 4 * * 0"
EOF

# Webserver variables
cat > group_vars/role_webserver.yml << 'EOF'
---
http_port: 80
https_port: 443
max_connections: 200
EOF

# Database variables
cat > group_vars/role_database.yml << 'EOF'
---
db_port: 5432
max_connections: 100
shared_buffers: 256MB
EOF
```

#### Step 8: Create Playbook Using Dynamic Groups

```bash
cat > playbooks/configure_servers.yml << 'EOF'
---
- name: Configure production web servers
  hosts: env_production:&role_webserver
  gather_facts: yes
  
  tasks:
    - name: Display server info
      debug:
        msg: |
          Host: {{ inventory_hostname }}
          Environment: {{ environment }}
          Role: {{ role }}
          HTTP Port: {{ http_port }}
          Backup Schedule: {{ backup_schedule }}
    
    - name: Install nginx
      apt:
        name: nginx
        state: present
        update_cache: yes
      become: yes

- name: Configure production database servers
  hosts: env_production:&role_database
  gather_facts: yes
  
  tasks:
    - name: Display database info
      debug:
        msg: |
          Host: {{ inventory_hostname }}
          Environment: {{ environment }}
          DB Port: {{ db_port }}
          Max Connections: {{ max_connections }}
    
    - name: Install PostgreSQL
      apt:
        name: postgresql
        state: present
        update_cache: yes
      become: yes

- name: Configure staging servers (all roles)
  hosts: env_staging
  gather_facts: yes
  
  tasks:
    - name: Display staging info
      debug:
        msg: |
          Host: {{ inventory_hostname }}
          Environment: {{ environment }}
          Log Level: {{ log_level }}
EOF
```

#### Step 9: Run the Configuration Playbook

```bash
# Check syntax
ansible-playbook -i inventories/openstack.yml playbooks/configure_servers.yml --syntax-check

# Dry run
ansible-playbook -i inventories/openstack.yml playbooks/configure_servers.yml --check

# Execute
ansible-playbook -i inventories/openstack.yml playbooks/configure_servers.yml
```

#### Step 10: Advanced Targeting

```bash
# Target only production webservers
ansible env_production:&role_webserver -i inventories/openstack.yml -m ping

# Target all except staging
ansible 'all:!env_staging' -i inventories/openstack.yml -m ping

# Target specific application
ansible app_ecommerce -i inventories/openstack.yml -m ping

# Run ad-hoc command on production databases
ansible env_production:&role_database -i inventories/openstack.yml -a "df -h" -b
```

---

## 💡 Best Practices for Dynamic Inventory

1. **Use Metadata/Tags Extensively**
   - Tag instances with environment, role, application
   - Use consistent naming conventions

2. **Cache Inventory Data**
   ```yaml
   cache: yes
   cache_plugin: jsonfile
   cache_timeout: 3600
   cache_connection: /tmp/ansible_inventory_cache
   ```

3. **Handle Connection Details**
   - Use `compose` to set ansible_host
   - Define ansible_user based on OS
   - Specify SSH keys per environment

4. **Group by Multiple Criteria**
   ```yaml
   keyed_groups:
     - key: tags.environment
     - key: tags.role
     - key: tags.application
     - key: placement.region
   ```

5. **Use Inventory Directory**
   ```bash
   inventories/
   ├── 01-static-hosts.yml
   ├── 02-aws_ec2.yml
   ├── 03-azure_rm.yml
   └── 04-openstack.yml
   ```

6. **Filter Unwanted Hosts**
   ```yaml
   filters:
     instance-state-name: running
   exclude_host_filters:
     - powerstate != 'running'
   ```

7. **Test Before Deployment**
   ```bash
   ansible-inventory -i inventories/ --list | jq
   ansible-inventory -i inventories/ --graph
   ```

---

## 📊 Dynamic vs Static Inventory Comparison

| Feature | Static Inventory | Dynamic Inventory |
|---------|------------------|-------------------|
| Maintenance | Manual updates | Automatic |
| Scalability | Limited | Excellent |
| Auto-scaling | Not supported | Supported |
| Cloud Integration | None | Native |
| Accuracy | Can be outdated | Always current |
| Complexity | Simple | Moderate |

---

## 🐛 Troubleshooting

### Common Issues

1. **Inventory Plugin Not Found**
   ```bash
   # Install required collection
   ansible-galaxy collection install amazon.aws
   ```

2. **Authentication Failures**
   ```bash
   # Verify credentials
   export ANSIBLE_DEBUG=1
   ansible-inventory -i inventories/aws_ec2.yml --list
   ```

3. **No Hosts Discovered**
   ```bash
   # Check filters and regions
   ansible-inventory -i inventories/aws_ec2.yml --list -vvv
   ```

4. **Connection Issues**
   ```bash
   # Verify ansible_host is set correctly
   ansible-inventory -i inventories/ --list | jq '.["_meta"]["hostvars"]'
   ```

---

## ✅ Checklist

- [ ] Installed required collections
- [ ] Configured cloud credentials
- [ ] Created inventory plugin configuration
- [ ] Tested with --list flag
- [ ] Verified group creation
- [ ] Set up group_vars for dynamic groups
- [ ] Tested playbook with dynamic inventory
- [ ] Implemented caching (optional)
- [ ] Documented inventory configuration

---

## 🔗 Next Steps

Continue to **Topic 3: How to Differentiate Staging vs Production** to learn environment separation strategies.
