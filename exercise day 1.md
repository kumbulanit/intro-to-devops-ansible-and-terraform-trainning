### **Objective**  
This exercise is designed to demonstrate the following:  
1. Setting up and customizing the Ansible configuration file (`ansible.cfg`).  
2. Understanding and creating an inventory file.  
3. Using Ansible roles to automate tasks.  
4. Installing Docker, creating Ubuntu containers, and managing them as web servers (`web1` and `web2`) using Ansible.  
---

### **Step 1: Prepare the Ansible Project Structure**
1. Create the following directory structure for your project:

   ```bash
   mkdir -p ansible_exercise/{inventory,roles/{common,webserver}/tasks,playbooks}
   cd ansible_exercise
   ```

2. Navigate to the `ansible_exercise` directory and create these files:  
   - `ansible.cfg`  
   - `inventory/static_hosts`  
   - `playbooks/site.yml`  

---

### **Step 2: Configure Ansible**
1. **`ansible.cfg`**:  
   Create and configure the Ansible configuration file to set paths and options:

   ```ini
   [defaults]
   inventory = ./inventory/static_hosts
   roles_path = ./roles
   host_key_checking = False
   retry_files_enabled = False
   log_path = ./ansible.log
   ```

2. **Static Inventory File**:  
   Add two host entries representing the Docker containers:

   ```ini
   [local]
   localhost ansible_connection=local

   [web]
   web1 ansible_host=127.0.0.1 ansible_port=2222 ansible_user=root
   web2 ansible_host=127.0.0.1 ansible_port=2223 ansible_user=root
   ```

---

### **Step 3: Create the Common Role**
The `common` role will install Docker and set up the containers.

1. In `roles/common/tasks/main.yml`, add tasks for Docker installation and container creation:

   ```yaml
   ---
   - name: Install prerequisites for Docker
     apt:
       name: "{{ item }}"
       state: present
       update_cache: yes
     loop:
       - apt-transport-https
       - ca-certificates
       - curl
       - software-properties-common

   - name: Add Docker GPG key and repository
     shell: |
       curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
       echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

   - name: Install Docker and related packages
      ansible.builtin.apt:
        name: "{{ item }}"
        state: present
        update_cache: true
      loop:
        - docker-ce
        - docker-ce-cli
        - containerd.io
        - docker-buildx-plugin
        - docker-compose-plugin

    - name: Add Docker group
      ansible.builtin.group:
        name: docker
        state: present

    - name: Add user to Docker group
      ansible.builtin.user:
        name: "{{ ansible_user }}"
        groups: docker
        append: true

    - name: Enable and start Docker services
      ansible.builtin.systemd:
        name: "{{ item }}"
        enabled: true
        state: started
      loop:
        - docker.service
        - containerd.service

   - name: Pull  image for containers
     docker_image:
       name: httpd
       source: pull

   - name: Create and start web1 container
     docker_container:
       name: web1
       image: httpd
       state: started
       ports:
         - "2222:80"

   - name: Create and start web2 container
     docker_container:
       name: web2
       image: httpd
       state: started
       ports:
         - "2223:80"
       
   ```

---

### **Step 4: Create the Webserver Role**
The `webserver` role will install and configure a web server (e.g., Nginx) on the containers.

1. In `roles/webserver/tasks/main.yml`, add tasks to install and configure Nginx:

   ```yaml
   ---
   - name: Install Nginx
     apt:
       name: nginx
       state: present
       update_cache: yes

   - name: Start and enable Nginx
     service:
       name: nginx
       state: started
       enabled: yes

   - name: Deploy a sample HTML page
     copy:
       dest: /var/www/html/index.html
       content: |
         <html>
         <head><title>Web Server {{ inventory_hostname }}</title></head>
         <body><h1>Welcome to {{ inventory_hostname }}</h1></body>
         </html>
   ```

---

### **Step 5: Create the Playbook**
1. In `playbooks/site.yml`, define the playbook that runs the roles:

   ```yaml
   ---
   - name: Set up Docker and Containers
     hosts: local
     roles:
       - common

   - name: Install Web Server on Docker Containers
     hosts: web
     roles:
       - webserver
   ```

---

### **Step 6: Configure the Environment**
1. Run the playbook to set up Docker and the containers:

   ```bash
   ansible-playbook playbooks/site.yml
   ```

2. Verify the containers are running:

   ```bash
   docker ps
   ```

3. Test SSH connectivity to the containers:

   ```bash
   ansible -m ping web
   ```

---

### **Step 7: Dynamic Inventory (Optional)**
1. Create a dynamic inventory script (`inventory/docker_dynamic.py`):

   ```python
   #!/usr/bin/env python3
   import docker
   import json

   client = docker.from_env()
   containers = client.containers.list()

   inventory = {"_meta": {"hostvars": {}}}

   for container in containers:
       if "web" in container.name:
           inventory["_meta"]["hostvars"][container.name] = {
               "ansible_host": "127.0.0.1",
               "ansible_port": int(container.attrs['NetworkSettings']['Ports']['22/tcp'][0]['HostPort']),
               "ansible_user": "root"
           }
   inventory["web"] = [c.name for c in containers if "web" in c.name]

   print(json.dumps(inventory, indent=2))
   ```

2. Make the script executable:

   ```bash
   chmod +x inventory/docker_dynamic.py
   ```

3. Update `ansible.cfg` to use the dynamic inventory:

   ```ini
   inventory = ./inventory/docker_dynamic.py
   ```

---

### **Step 8: Verify the Web Servers**
1. Open your browser and access the web servers:
   - `http://127.0.0.1:2222`
   - `http://127.0.0.1:2223`

2. Confirm that each page displays the unique hostname (`web1` or `web2`).

---

### **Extended Challenges**
1. Add a task to secure the web servers with TLS certificates using Ansible.
2. Use Ansible Vault to encrypt sensitive information (e.g., SSH keys).
3. Write a cleanup playbook to remove the containers and reset the environment.

