# ☁️ Topic 5: AWX Installation on OpenStack VM

## 🎯 Objective

Deploy Ansible AWX on an OpenStack virtual machine using Ansible automation, with complete OpenStack configuration and integration.

---

## 📋 Prerequisites

### OpenStack Requirements

```yaml
OpenStack Version: Train or later
Available Quota:
  - Instances: 1
  - vCPUs: 4
  - RAM: 8192 MB
  - Disk: 40 GB
  - Floating IPs: 1
  - Security Groups: 2
```

### Local Machine Requirements

- Ansible 2.9+
- Python 3.8+
- `openstacksdk` Python package
- OpenStack credentials (`clouds.yaml`)

---

## 🔧 Part 1: OpenStack Configuration

### Step 1: Install OpenStack SDK

```bash
# Install Python OpenStack SDK
pip3 install openstacksdk

# Install Ansible OpenStack collection
ansible-galaxy collection install openstack.cloud

# Verify installation
ansible-galaxy collection list | grep openstack
# Expected: openstack.cloud   2.1.0 or later
```

### Step 2: Configure OpenStack Credentials

#### Option A: Using clouds.yaml (Recommended)

Create `~/.config/openstack/clouds.yaml`:

```yaml
---
clouds:
  devstack:
    auth:
      auth_url: http://YOUR_OPENSTACK_IP/identity
      username: admin
      password: your_admin_password
      project_name: admin
      project_domain_name: Default
      user_domain_name: Default
    region_name: RegionOne
    interface: public
    identity_api_version: 3
    
  production:
    auth:
      auth_url: http://YOUR_PROD_OPENSTACK_IP/identity
      username: prod_user
      password: prod_password
      project_name: production
      project_domain_name: Default
      user_domain_name: Default
    region_name: RegionOne
    interface: public
    identity_api_version: 3
```

**Set permissions:**

```bash
chmod 600 ~/.config/openstack/clouds.yaml
```

#### Option B: Using Environment Variables

```bash
export OS_AUTH_URL=http://YOUR_OPENSTACK_IP/identity
export OS_USERNAME=admin
export OS_PASSWORD=your_admin_password
export OS_PROJECT_NAME=admin
export OS_PROJECT_DOMAIN_NAME=Default
export OS_USER_DOMAIN_NAME=Default
export OS_REGION_NAME=RegionOne
export OS_IDENTITY_API_VERSION=3
export OS_INTERFACE=public
```

### Step 3: Test OpenStack Connection

```bash
# Test with OpenStack CLI
openstack server list

# Test with Ansible
ansible localhost -m openstack.cloud.server_info \
  -a "cloud=devstack" \
  -e "ansible_python_interpreter=/usr/bin/python3"
```

---

## 🚀 Part 2: Automated AWX Deployment

### Complete Deployment Playbook

Create `deploy-awx-openstack.yml`:

```yaml
---
- name: Deploy AWX on OpenStack VM
  hosts: localhost
  gather_facts: yes
  vars:
    # OpenStack cloud from clouds.yaml
    cloud_name: devstack
    
    # VM Configuration
    vm_name: awx-server
    flavor: m1.large        # 4 vCPU, 8GB RAM
    image: ubuntu-22.04     # Ubuntu 22.04 LTS
    key_name: my-keypair
    network_name: private
    security_group: awx-sg
    floating_ip_pool: public
    
    # AWX Configuration
    awx_admin_password: "SecureAWXPassword123!"
    awx_version: "23.5.0"
    
    # SSH Configuration
    ansible_ssh_private_key_file: "~/.ssh/id_rsa"
    ansible_user: ubuntu

  tasks:
    - name: Create security group for AWX
      openstack.cloud.security_group:
        cloud: "{{ cloud_name }}"
        name: "{{ security_group }}"
        description: "Security group for AWX server"
        state: present

    - name: Add security group rules
      openstack.cloud.security_group_rule:
        cloud: "{{ cloud_name }}"
        security_group: "{{ security_group }}"
        protocol: "{{ item.protocol }}"
        port_range_min: "{{ item.port }}"
        port_range_max: "{{ item.port }}"
        remote_ip_prefix: "{{ item.cidr }}"
        state: present
      loop:
        - { protocol: tcp, port: 22, cidr: '0.0.0.0/0' }      # SSH
        - { protocol: tcp, port: 80, cidr: '0.0.0.0/0' }      # HTTP
        - { protocol: tcp, port: 443, cidr: '0.0.0.0/0' }     # HTTPS
        - { protocol: tcp, port: 8080, cidr: '0.0.0.0/0' }    # AWX
        - { protocol: icmp, port: -1, cidr: '0.0.0.0/0' }     # ICMP

    - name: Create SSH keypair
      openstack.cloud.keypair:
        cloud: "{{ cloud_name }}"
        name: "{{ key_name }}"
        public_key_file: "{{ ansible_ssh_private_key_file }}.pub"
        state: present

    - name: Launch AWX VM instance
      openstack.cloud.server:
        cloud: "{{ cloud_name }}"
        name: "{{ vm_name }}"
        flavor: "{{ flavor }}"
        image: "{{ image }}"
        key_name: "{{ key_name }}"
        network: "{{ network_name }}"
        security_groups:
          - "{{ security_group }}"
          - default
        auto_ip: yes
        wait: yes
        timeout: 600
        meta:
          group: awx
          environment: production
      register: awx_vm

    - name: Show VM information
      debug:
        msg: |
          VM Name: {{ awx_vm.server.name }}
          VM ID: {{ awx_vm.server.id }}
          Private IP: {{ awx_vm.server.private_v4 }}
          Public IP: {{ awx_vm.server.public_v4 }}

    - name: Allocate floating IP
      openstack.cloud.floating_ip:
        cloud: "{{ cloud_name }}"
        server: "{{ vm_name }}"
        network: "{{ floating_ip_pool }}"
        wait: yes
        timeout: 180
      register: floating_ip

    - name: Wait for SSH to be available
      wait_for:
        host: "{{ floating_ip.floating_ip.floating_ip_address }}"
        port: 22
        delay: 10
        timeout: 300
        state: started

    - name: Add AWX VM to inventory
      add_host:
        name: awx-vm
        ansible_host: "{{ floating_ip.floating_ip.floating_ip_address }}"
        ansible_user: "{{ ansible_user }}"
        ansible_ssh_private_key_file: "{{ ansible_ssh_private_key_file }}"
        ansible_python_interpreter: /usr/bin/python3
        groups: awx_servers

    - name: Save VM info to file
      copy:
        content: |
          AWX Server Information
          =====================
          VM Name: {{ awx_vm.server.name }}
          VM ID: {{ awx_vm.server.id }}
          Private IP: {{ awx_vm.server.private_v4 }}
          Public IP: {{ floating_ip.floating_ip.floating_ip_address }}
          SSH Access: ssh {{ ansible_user }}@{{ floating_ip.floating_ip.floating_ip_address }}
          AWX URL: http://{{ floating_ip.floating_ip.floating_ip_address }}:8080
        dest: "./awx-server-info.txt"

- name: Configure and Install AWX
  hosts: awx_servers
  become: yes
  gather_facts: yes
  vars:
    awx_admin_password: "SecureAWXPassword123!"
    awx_version: "23.5.0"

  tasks:
    - name: Update apt cache
      apt:
        update_cache: yes
        cache_valid_time: 3600

    - name: Install required packages
      apt:
        name:
          - apt-transport-https
          - ca-certificates
          - curl
          - gnupg
          - lsb-release
          - python3-pip
          - git
        state: present

    - name: Add Docker GPG key
      apt_key:
        url: https://download.docker.com/linux/ubuntu/gpg
        state: present

    - name: Add Docker repository
      apt_repository:
        repo: "deb [arch=amd64] https://download.docker.com/linux/ubuntu {{ ansible_distribution_release }} stable"
        state: present

    - name: Install Docker
      apt:
        name:
          - docker-ce
          - docker-ce-cli
          - containerd.io
          - docker-compose-plugin
        state: present
        update_cache: yes

    - name: Add ubuntu user to docker group
      user:
        name: ubuntu
        groups: docker
        append: yes

    - name: Start and enable Docker
      systemd:
        name: docker
        state: started
        enabled: yes

    - name: Create AWX directory
      file:
        path: /opt/awx
        state: directory
        mode: '0755'

    - name: Create docker-compose.yml for AWX
      copy:
        content: |
          version: '3.8'
          
          services:
            postgres:
              image: postgres:13
              container_name: awx-postgres
              environment:
                POSTGRES_DB: awx
                POSTGRES_USER: awx
                POSTGRES_PASSWORD: awxpass
                PGDATA: /var/lib/postgresql/data/pgdata
              volumes:
                - postgres-data:/var/lib/postgresql/data/pgdata
              networks:
                - awx-network
              restart: unless-stopped
          
            redis:
              image: redis:7
              container_name: awx-redis
              networks:
                - awx-network
              restart: unless-stopped
          
            awx-web:
              image: quay.io/ansible/awx:{{ awx_version }}
              container_name: awx-web
              hostname: awx-web
              user: root
              environment:
                DATABASE_HOST: postgres
                DATABASE_PORT: 5432
                DATABASE_NAME: awx
                DATABASE_USER: awx
                DATABASE_PASSWORD: awxpass
                REDIS_HOST: redis
                REDIS_PORT: 6379
                AWX_ADMIN_USER: admin
                AWX_ADMIN_PASSWORD: {{ awx_admin_password }}
              volumes:
                - awx-projects:/var/lib/awx/projects
              ports:
                - "8080:8052"
              networks:
                - awx-network
              depends_on:
                - postgres
                - redis
              command: >
                bash -c "
                awx-manage migrate --noinput &&
                awx-manage create_preload_data &&
                awx-manage provision_instance --hostname=awx-web &&
                awx-manage register_queue --queuename=default --hostnames=awx-web &&
                supervisord -c /etc/supervisord.conf
                "
              restart: unless-stopped
          
            awx-task:
              image: quay.io/ansible/awx:{{ awx_version }}
              container_name: awx-task
              hostname: awx-task
              user: root
              environment:
                DATABASE_HOST: postgres
                DATABASE_PORT: 5432
                DATABASE_NAME: awx
                DATABASE_USER: awx
                DATABASE_PASSWORD: awxpass
                REDIS_HOST: redis
                REDIS_PORT: 6379
              volumes:
                - awx-projects:/var/lib/awx/projects
              networks:
                - awx-network
              depends_on:
                - postgres
                - redis
                - awx-web
              command: >
                bash -c "
                awx-manage provision_instance --hostname=awx-task &&
                awx-manage register_queue --queuename=default --hostnames=awx-task &&
                supervisord -c /etc/supervisord.conf
                "
              restart: unless-stopped
          
          volumes:
            postgres-data:
            awx-projects:
          
          networks:
            awx-network:
              driver: bridge
        dest: /opt/awx/docker-compose.yml
        mode: '0644'

    - name: Start AWX containers
      community.docker.docker_compose:
        project_src: /opt/awx
        state: present
        pull: yes
      environment:
        DOCKER_CLIENT_TIMEOUT: "300"
        COMPOSE_HTTP_TIMEOUT: "300"

    - name: Wait for AWX to be ready
      uri:
        url: "http://localhost:8080/api/v2/ping/"
        status_code: 200
      register: result
      until: result.status == 200
      retries: 30
      delay: 10

    - name: Display AWX access information
      debug:
        msg: |
          ========================================
          AWX Installation Complete!
          ========================================
          URL: http://{{ ansible_host }}:8080
          Username: admin
          Password: {{ awx_admin_password }}
          ========================================
```

### Run the Deployment

```bash
# Run playbook
ansible-playbook deploy-awx-openstack.yml

# Expected output:
# - Security group created
# - VM launched
# - Floating IP assigned
# - Docker installed
# - AWX deployed
# - Access information displayed

# Access AWX
# URL will be shown at the end of playbook
# Example: http://192.168.1.100:8080
```

---

## 🔧 Part 3: OpenStack Dynamic Inventory for AWX

### Configure AWX to Use OpenStack Inventory

#### Step 1: Create OpenStack Credential in AWX

1. **AWX UI → Credentials → Add**
2. **Credential Type:** `OpenStack`
3. **Name:** `OpenStack DevStack`
4. **Host (Auth URL):** `http://YOUR_OPENSTACK_IP/identity`
5. **Username:** `admin`
6. **Password:** `your_password`
7. **Project Name:** `admin`
8. **Project Domain Name:** `Default`
9. **User Domain Name:** `Default`

#### Step 2: Create Inventory Source

1. **AWX UI → Inventories → Add**
2. **Name:** `OpenStack Dynamic Inventory`
3. **Organization:** `Default`
4. **Sources → Add:**
   - **Name:** `OpenStack VMs`
   - **Source:** `OpenStack`
   - **Credential:** `OpenStack DevStack`
   - **Update options:**
     - ✅ Overwrite
     - ✅ Update on launch
   - **Source Variables:**

```yaml
---
# Filter instances
filters:
  metadata:
    environment: production

# Group instances
compose:
  ansible_host: public_v4
  ansible_user: ubuntu
  
groups:
  webservers: "'web' in metadata.group"
  databases: "'db' in metadata.group"
  loadbalancers: "'lb' in metadata.group"

# Add metadata as host variables
hostvar_expressions:
  environment: metadata.environment
  instance_id: id
  flavor: flavor.name
```

5. **Click Sync** to pull inventory

---

## 📁 Part 4: Complete Project Structure

Create repository: `awx-openstack-automation`

```bash
# Create structure
mkdir -p awx-openstack-automation/{playbooks,roles,inventories,group_vars,host_vars}
cd awx-openstack-automation

# Initialize git
git init
```

### File: `clouds.yaml`

```yaml
---
clouds:
  devstack:
    auth:
      auth_url: http://YOUR_OPENSTACK_IP/identity
      username: admin
      password: changeme
      project_name: admin
      project_domain_name: Default
      user_domain_name: Default
    region_name: RegionOne
    interface: public
    identity_api_version: 3
```

### File: `inventories/openstack.yml`

```yaml
---
plugin: openstack.cloud.openstack
clouds:
  - devstack
expand_hostvars: yes
fail_on_errors: yes
all_projects: no
compose:
  ansible_host: public_v4
  ansible_user: ubuntu
groups:
  webservers: "'web' in metadata.group"
  databases: "'db' in metadata.group"
keyed_groups:
  - key: metadata.environment
    prefix: env
  - key: metadata.application
    prefix: app
```

### File: `playbooks/provision-infrastructure.yml`

```yaml
---
- name: Provision OpenStack Infrastructure
  hosts: localhost
  gather_facts: no
  vars:
    cloud_name: devstack
    instances:
      - name: web-server-1
        flavor: m1.medium
        image: ubuntu-22.04
        group: web
        environment: production
      - name: web-server-2
        flavor: m1.medium
        image: ubuntu-22.04
        group: web
        environment: production
      - name: db-server-1
        flavor: m1.large
        image: ubuntu-22.04
        group: db
        environment: production

  tasks:
    - name: Launch instances
      openstack.cloud.server:
        cloud: "{{ cloud_name }}"
        name: "{{ item.name }}"
        flavor: "{{ item.flavor }}"
        image: "{{ item.image }}"
        key_name: my-keypair
        network: private
        security_groups:
          - default
          - web-sg
        auto_ip: yes
        meta:
          group: "{{ item.group }}"
          environment: "{{ item.environment }}"
        state: present
      loop: "{{ instances }}"
```

### File: `playbooks/deploy-application.yml`

```yaml
---
- name: Deploy Application on OpenStack VMs
  hosts: webservers
  become: yes
  
  tasks:
    - name: Install nginx
      apt:
        name: nginx
        state: present
        update_cache: yes
    
    - name: Start nginx
      systemd:
        name: nginx
        state: started
        enabled: yes
    
    - name: Deploy application
      copy:
        content: |
          <!DOCTYPE html>
          <html>
          <head><title>{{ inventory_hostname }}</title></head>
          <body>
            <h1>Server: {{ inventory_hostname }}</h1>
            <p>IP: {{ ansible_host }}</p>
            <p>Environment: {{ environment }}</p>
          </body>
          </html>
        dest: /var/www/html/index.html
```

---

## 🎯 Part 5: AWX Job Templates

### Job Template 1: Provision Infrastructure

**AWX UI → Templates → Add Job Template:**

```yaml
Name: Provision OpenStack Infrastructure
Job Type: Run
Inventory: OpenStack Dynamic Inventory
Project: AWX OpenStack Automation
Playbook: playbooks/provision-infrastructure.yml
Credentials:
  - OpenStack DevStack
  - SSH Key
Extra Variables:
  cloud_name: devstack
Options:
  ✅ Enable Webhook
  ✅ Concurrent Jobs
```

### Job Template 2: Deploy Application

```yaml
Name: Deploy Web Application
Job Type: Run
Inventory: OpenStack Dynamic Inventory
Project: AWX OpenStack Automation
Playbook: playbooks/deploy-application.yml
Credentials:
  - SSH Key
Limit: webservers
Survey:
  - Variable: environment
    Type: Multiple Choice
    Choices: [production, staging, development]
    Required: Yes
```

---

## ✅ Verification

### Test AWX Installation

```bash
# Check AWX is running
curl http://AWX_IP:8080/api/v2/ping/

# Login
curl -X POST http://AWX_IP:8080/api/v2/tokens/ \
  -u admin:SecureAWXPassword123! \
  -H "Content-Type: application/json"
```

### Test OpenStack Integration

1. **AWX UI → Inventories → OpenStack Dynamic Inventory**
2. **Click Sync**
3. **Hosts tab** - should show OpenStack VMs
4. **Groups tab** - should show webservers, databases, etc.

### Run a Job

1. **AWX UI → Templates → Deploy Web Application**
2. **Click Launch**
3. **Select Survey options**
4. **Monitor job output**

---

## 🛠️ Troubleshooting

### Issue: Cannot connect to OpenStack

```bash
# Test OpenStack connection
openstack --os-cloud=devstack server list

# Check clouds.yaml
cat ~/.config/openstack/clouds.yaml

# Test from AWX container
docker exec -it awx-task bash
python3 -c "import openstack; conn = openstack.connect(cloud='devstack'); print(conn.list_servers())"
```

### Issue: Dynamic inventory not updating

```yaml
# Check inventory source logs in AWX UI
# Verify clouds.yaml is mounted in AWX container
# Check source variables syntax
```

### Issue: SSH connection failures

```bash
# Test SSH from AWX VM
ssh -i ~/.ssh/id_rsa ubuntu@TARGET_VM_IP

# Check security group rules
openstack security group rule list awx-sg

# Verify floating IP
openstack floating ip list
```

---

## 📚 Additional Configuration

### Configure AWX to Use OpenStack credentials.yaml

Mount clouds.yaml in AWX containers:

```yaml
# In docker-compose.yml, add volumes:
volumes:
  - /home/ubuntu/.config/openstack:/etc/openstack:ro
```

---

## 🔗 Next Steps

Continue to **Topic 6: Complete Exercise** for a hands-on lab deploying a full application stack using AWX and OpenStack.
