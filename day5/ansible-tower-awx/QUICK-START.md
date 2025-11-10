# ⚡ Quick Start Guide: AWX + OpenStack Integration

## 🎯 Goal

Get AWX running on OpenStack and deploy your first automation job in **under 1 hour**.

---

## ✅ Prerequisites Checklist

- [ ] OpenStack environment accessible
- [ ] `clouds.yaml` configured with your OpenStack credentials
- [ ] SSH key pair created (`~/.ssh/id_rsa` and `~/.ssh/id_rsa.pub`)
- [ ] Ansible 2.9+ installed
- [ ] Python 3 with `openstacksdk` installed
- [ ] OpenStack quota: 1 VM, 4 vCPUs, 8GB RAM, 1 Floating IP

---

## 🚀 5-Step Quick Start

### Step 1: Install Dependencies (5 minutes)

```bash
# Install OpenStack SDK
pip3 install openstacksdk

# Install OpenStack Ansible Collection
ansible-galaxy collection install openstack.cloud

# Verify
ansible-galaxy collection list | grep openstack
```

### Step 2: Configure OpenStack (5 minutes)

Create `~/.config/openstack/clouds.yaml`:

```yaml
clouds:
  mycloud:
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

**Replace:**
- `YOUR_OPENSTACK_IP` with your OpenStack server IP
- `your_password` with actual password

**Test connection:**

```bash
openstack --os-cloud=mycloud server list
```

### Step 3: Deploy AWX VM (20 minutes)

Create `quick-deploy-awx.yml`:

```yaml
---
- name: Quick Deploy AWX on OpenStack
  hosts: localhost
  vars:
    cloud_name: mycloud
    awx_admin_password: "AWXPassword123!"

  tasks:
    - name: Create security group
      openstack.cloud.security_group:
        cloud: "{{ cloud_name }}"
        name: awx-quick-sg
        description: AWX security group
      
    - name: Add security rules
      openstack.cloud.security_group_rule:
        cloud: "{{ cloud_name }}"
        security_group: awx-quick-sg
        protocol: tcp
        port_range_min: "{{ item }}"
        port_range_max: "{{ item }}"
        remote_ip_prefix: 0.0.0.0/0
      loop: [22, 80, 8080, 443]
      ignore_errors: yes

    - name: Launch AWX VM
      openstack.cloud.server:
        cloud: "{{ cloud_name }}"
        name: awx-server
        flavor: m1.large
        image: ubuntu-22.04
        key_name: my-keypair
        network: private
        security_groups: [awx-quick-sg, default]
        auto_ip: yes
        wait: yes
      register: awx_vm

    - name: Wait for SSH
      wait_for:
        host: "{{ awx_vm.server.public_v4 }}"
        port: 22
        delay: 10
        timeout: 300

    - name: Add to inventory
      add_host:
        name: awx-server
        ansible_host: "{{ awx_vm.server.public_v4 }}"
        ansible_user: ubuntu
        ansible_ssh_private_key_file: ~/.ssh/id_rsa

    - name: Save connection info
      copy:
        content: |
          AWX Server: {{ awx_vm.server.public_v4 }}
          SSH: ssh ubuntu@{{ awx_vm.server.public_v4 }}
          URL: http://{{ awx_vm.server.public_v4 }}:8080
        dest: ./awx-connection.txt

- name: Install AWX
  hosts: awx-server
  become: yes
  vars:
    awx_version: "23.5.0"
    awx_admin_password: "AWXPassword123!"

  tasks:
    - name: Update and install Docker
      shell: |
        apt update
        apt install -y docker.io docker-compose python3-pip
        systemctl start docker
        systemctl enable docker
        usermod -aG docker ubuntu

    - name: Create AWX directory
      file:
        path: /opt/awx
        state: directory

    - name: Create docker-compose.yml
      copy:
        dest: /opt/awx/docker-compose.yml
        content: |
          version: '3.8'
          services:
            postgres:
              image: postgres:13
              environment:
                POSTGRES_DB: awx
                POSTGRES_USER: awx
                POSTGRES_PASSWORD: awxpass
              volumes:
                - postgres-data:/var/lib/postgresql/data
              restart: unless-stopped
            
            redis:
              image: redis:7
              restart: unless-stopped
            
            awx-web:
              image: quay.io/ansible/awx:{{ awx_version }}
              hostname: awx-web
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
              depends_on:
                - postgres
                - redis
              command: >
                bash -c "awx-manage migrate --noinput &&
                awx-manage create_preload_data &&
                awx-manage provision_instance --hostname=awx-web &&
                awx-manage register_queue --queuename=default --hostnames=awx-web &&
                supervisord -c /etc/supervisord.conf"
              restart: unless-stopped
            
            awx-task:
              image: quay.io/ansible/awx:{{ awx_version }}
              hostname: awx-task
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
              depends_on:
                - postgres
                - redis
                - awx-web
              command: >
                bash -c "awx-manage provision_instance --hostname=awx-task &&
                awx-manage register_queue --queuename=default --hostnames=awx-task &&
                supervisord -c /etc/supervisord.conf"
              restart: unless-stopped
          
          volumes:
            postgres-data:
            awx-projects:

    - name: Start AWX
      shell: |
        cd /opt/awx
        docker-compose up -d
      environment:
        DOCKER_CLIENT_TIMEOUT: "300"

    - name: Wait for AWX to be ready
      uri:
        url: http://localhost:8080/api/v2/ping/
        status_code: 200
      register: result
      until: result.status == 200
      retries: 30
      delay: 10

    - name: Display access info
      debug:
        msg: |
          ========================================
          AWX is ready!
          URL: http://{{ ansible_host }}:8080
          Username: admin
          Password: {{ awx_admin_password }}
          ========================================
```

**Run deployment:**

```bash
ansible-playbook quick-deploy-awx.yml
```

**Expected time:** 15-20 minutes

### Step 4: Access AWX (2 minutes)

1. **Get connection info:**

   ```bash
   cat awx-connection.txt
   ```

2. **Open in browser:**

   ```
   http://YOUR_AWX_IP:8080
   ```

3. **Login:**
   - Username: `admin`
   - Password: `AWXPassword123!`

### Step 5: Create First Job (15 minutes)

#### A. Add OpenStack Credential

1. **AWX UI → Credentials → Add**
2. **Name:** `My OpenStack`
3. **Credential Type:** `OpenStack`
4. **Fill in your OpenStack details** (from clouds.yaml)
5. **Save**

#### B. Add SSH Credential

1. **Credentials → Add**
2. **Name:** `SSH Key`
3. **Credential Type:** `Machine`
4. **Username:** `ubuntu`
5. **SSH Private Key:** Paste your `~/.ssh/id_rsa`
6. **Save**

#### C. Create Inventory

1. **Inventories → Add**
2. **Name:** `OpenStack Inventory`
3. **Save**
4. **Sources → Add**
   - **Name:** `OpenStack VMs`
   - **Source:** `OpenStack`
   - **Credential:** `My OpenStack`
   - **Source Variables:**

     ```yaml
     expand_hostvars: yes
     compose:
       ansible_host: public_v4
       ansible_user: ubuntu
     ```

5. **Save and Sync**

#### D. Create Project

1. **Projects → Add**
2. **Name:** `Demo Project`
3. **SCM Type:** `Manual`
4. **Playbook Directory:** `/var/lib/awx/projects/demo`
5. **Save**

#### E. Create Simple Playbook Manually

```bash
# SSH to AWX server
ssh ubuntu@YOUR_AWX_IP

# Create playbook directory
sudo mkdir -p /var/lib/awx/projects/demo
cd /var/lib/awx/projects/demo

# Create simple playbook
sudo tee hello.yml << 'EOF'
---
- name: Hello World
  hosts: all
  gather_facts: yes
  tasks:
    - name: Display message
      debug:
        msg: |
          Hello from {{ inventory_hostname }}!
          OS: {{ ansible_distribution }} {{ ansible_distribution_version }}
          IP: {{ ansible_host }}
EOF

# Fix permissions
sudo chown -R awx:awx /var/lib/awx/projects/demo
```

#### F. Create Job Template

1. **Templates → Add Job Template**
2. **Name:** `Hello World`
3. **Job Type:** `Run`
4. **Inventory:** `OpenStack Inventory`
5. **Project:** `Demo Project`
6. **Playbook:** `hello.yml`
7. **Credentials:** Add `SSH Key`
8. **Save**

#### G. Run Your First Job!

1. **Click Launch** 🚀
2. **Watch the output**
3. **Success!** ✅

---

## 🎉 You Did It!

You now have:
- ✅ AWX running on OpenStack
- ✅ Dynamic inventory from OpenStack
- ✅ Your first successful automation job

---

## 🔗 Next Steps

### Immediate (10 minutes each)

1. **Add GitHub Project:**
   - Create GitHub repo with playbooks
   - Add GitHub credential to AWX
   - Create project linked to GitHub

2. **Try Dynamic Playbook:**
   - Install nginx on a test VM
   - Create job template
   - Run deployment

3. **Explore AWX UI:**
   - Check job history
   - View inventory hosts
   - Explore dashboard

### Short-term (1 hour each)

1. **Study**: Read full guides in this module
2. **Practice**: Complete comprehensive exercise
3. **Experiment**: Create workflows with multiple jobs
4. **Integrate**: Set up GitHub webhooks

### Long-term

1. **Production Setup:**
   - Implement RBAC
   - Configure LDAP/AD
   - Set up notifications
   - Deploy HA configuration

2. **Advanced Workflows:**
   - Multi-tier deployments
   - Rolling updates
   - Blue-green deployments
   - Disaster recovery

3. **Integration:**
   - Jenkins CI/CD
   - Monitoring (Prometheus/Grafana)
   - Secrets management (Vault)
   - Container orchestration (Kubernetes)

---

## 🆘 Troubleshooting

### AWX not accessible

```bash
# Check containers
ssh ubuntu@YOUR_AWX_IP
docker ps

# View logs
docker logs awx-web
docker logs awx-task

# Restart if needed
cd /opt/awx
docker-compose restart
```

### OpenStack connection fails

```bash
# Test from AWX container
docker exec -it awx-task bash
python3 -c "import openstack; conn = openstack.connect(cloud='mycloud'); print(conn.list_servers())"
```

### Inventory sync fails

- Verify clouds.yaml is correct
- Check OpenStack credential in AWX
- Review inventory source variables
- Check AWX task logs

---

## 📚 Full Documentation

For detailed guides, see:
- **Installation:** `04-awx-installation-local.md` or `05-awx-installation-openstack.md`
- **GitHub Integration:** `03-github-integration.md`
- **Complete Exercise:** `06-comprehensive-exercise.md`

---

## 🎯 Quick Reference Commands

```bash
# OpenStack CLI
openstack --os-cloud=mycloud server list
openstack --os-cloud=mycloud network list
openstack --os-cloud=mycloud security group list

# AWX Container Management
docker ps                        # List containers
docker logs -f awx-web          # View web logs
docker logs -f awx-task         # View task logs
docker-compose restart          # Restart all services
docker-compose down             # Stop AWX
docker-compose up -d            # Start AWX

# AWX API
curl http://AWX_IP:8080/api/v2/ping/
curl -u admin:PASSWORD http://AWX_IP:8080/api/v2/hosts/
```

---

**Congratulations! You're now ready to automate with AWX! 🚀**

For questions or issues, refer to the detailed documentation in this module.
