We’ll create a custom role that installs and configures an Nginx web server, includes handlers for service management, uses a template for the configuration file, and incorporates variables.

---

### **1. Setup**

1. **Install Ansible** (if not already done):
   ```bash
   sudo apt update
   sudo apt install -y ansible
   ```

2. **Set Up Project Directory**:
   ```bash
   mkdir -p ansible_project/{roles,inventory,playbooks}
   cd ansible_project
   ```

---

### **2. Create a Custom Role**

1. **Generate the Role**:
   Use `ansible-galaxy` to scaffold the custom role:
   ```bash
   ansible-galaxy init roles/nginx_custom
   ```

2. **Edit Role Components**:

#### **a) Tasks**
   Define tasks in `roles/nginx_custom/tasks/main.yml`:
   ```yaml
   # roles/nginx_custom/tasks/main.yml
   - name: Install Nginx
     apt:
       name: nginx
       state: present
       update_cache: yes

   - name: Deploy Nginx configuration
     template:
       src: nginx.conf.j2
       dest: /etc/nginx/sites-available/default
       owner: root
       group: root
       mode: '0644'
     notify:
       - Restart Nginx

   - name: Ensure Nginx is enabled and started
     service:
       name: nginx
       state: started
       enabled: yes
   ```

---

#### **b) Handlers**
   Define handlers in `roles/nginx_custom/handlers/main.yml`:
   ```yaml
   # roles/nginx_custom/handlers/main.yml
   - name: Restart Nginx
     service:
       name: nginx
       state: restarted
   ```

---

#### **c) Variables**
   Add variables in `roles/nginx_custom/defaults/main.yml`:
   ```yaml
   # roles/nginx_custom/defaults/main.yml
   server_port: 80
   server_name: localhost
   ```

---

#### **d) Templates**
   Create a template file `roles/nginx_custom/templates/nginx.conf.j2`:
   ```nginx
   # roles/nginx_custom/templates/nginx.conf.j2
daemon            off;
worker_processes  2;
user              www-data;

events {
    use           epoll;
    worker_connections  128;
}

error_log         logs/error.log info;

http {
    server_tokens off;
    include       mime.types;
    charset       utf-8;

    access_log    logs/access.log  combined;

    server {
        server_name   localhost;
        listen        127.0.0.1:80;

        error_page    500 502 503 504  /50x.html;

        location      / {
            root      html;
        }

    }

} 
   ```

---

#### **e) Files**
   Add a sample HTML file to `roles/nginx_custom/files/index.html`:
   ```html
   <!DOCTYPE html>
   <html>
   <head>
       <title>Welcome to Nginx!</title>
   </head>
   <body>
       <h1>Custom Nginx Role Example</h1>
   </body>
   </html>
   ```

   Update the `roles/nginx_custom/tasks/main.yml` to copy the file:
   ```yaml
   - name: Copy sample HTML file
     copy:
       src: index.html
       dest: /var/www/html/index.html
       owner: www-data
       group: www-data
       mode: '0644'
   ```

---

### **3. Use the Custom Role in a Playbook**

1. **Create Inventory**:
   Define `inventory/hosts` for localhost:
   ```ini
   [local]
   localhost ansible_connection=local
   ```

2. **Create the Playbook**:
   Write `playbooks/site.yml`:
   ```yaml
   # playbooks/site.yml
   - name: Configure Nginx on localhost
     hosts: localhost
     become: true
     roles:
       - role: nginx_custom
         vars:
           server_port: 8080
           server_name: example.com
   ```

---

### **4. Use a Pre-existing Role**

1. **Install a Pre-existing Role**:
   Install `geerlingguy.ntp` from Ansible Galaxy:
   ```bash
   ansible-galaxy install geerlingguy.ntp
   ```

2. **Update Playbook**:
   Modify `playbooks/site.yml` to include the pre-existing role:
   ```yaml
   - name: Configure localhost
     hosts: localhost
     become: true
     roles:
       - role: nginx_custom
         vars:
           server_port: 8080
           server_name: example.com
       - role: geerlingguy.ntp
         vars:
           ntp_timezone: UTC
   ```

---

### **5. Directory Structure**

The final structure:
```plaintext
ansible_project/
├── inventory/
│   └── hosts
├── playbooks/
│   └── site.yml
├── roles/
│   └── nginx_custom/
│       ├── defaults/
│       │   └── main.yml
│       ├── handlers/
│       │   └── main.yml
│       ├── tasks/
│       │   └── main.yml
│       ├── templates/
│       │   └── nginx.conf.j2
│       ├── files/
│       │   └── index.html
│       ├── meta/
│       │   └── main.yml
│       └── tests/
│           ├── inventory
│           └── test.yml
└── ~/.ansible/roles/
    └── geerlingguy.ntp/
```

---

### **6. Run the Playbook**

1. **Execute the Playbook**:
   ```bash
   ansible-playbook -i inventory/hosts playbooks/site.yml
   ```

2. **Verify**:
   - Access Nginx on `http://localhost:8080` or `http://example.com:8080`.
   - Check NTP service configuration by viewing `/etc/ntp.conf`.

---
