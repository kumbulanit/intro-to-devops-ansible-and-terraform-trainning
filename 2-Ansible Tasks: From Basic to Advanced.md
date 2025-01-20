### **Flowing Example of Ansible Tasks: From Basic to Advanced**

This example demonstrates tasks ranging from simple actions to more complex use cases, progressively introducing new Ansible features.

---

### **Basic Task: Installing a Package**

#### **Goal**: Ensure the `nginx` package is installed.

```yaml
- name: Install Nginx
  apt:
    name: nginx
    state: present
    update_cache: yes
```

---

### **Intermediate Task: Creating Files and Directories**

#### **Goal**: Create a directory and a file within it, then set permissions.

```yaml
- name: Create a directory
  file:
    path: /opt/my_app
    state: directory
    mode: '0755'

- name: Create a configuration file
  copy:
    dest: /opt/my_app/config.yml
    content: |
      app_name: MyApp
      version: 1.0.0
    mode: '0644'
```

---

### **Advanced Task: Using Variables**

#### **Goal**: Use a variable to specify the package name dynamically.

```yaml
- name: Install a package with a variable
  apt:
    name: "{{ package_name }}"
    state: present
  vars:
    package_name: htop
```

---

### **Advanced Task: Using Loops**

#### **Goal**: Install multiple packages.

```yaml
- name: Install essential tools
  apt:
    name: "{{ item }}"
    state: present
  loop:
    - vim
    - git
    - curl
```

---

### **Advanced Task: Conditional Execution**

#### **Goal**: Install `nginx` only if the OS is Debian-based.

```yaml
- name: Install Nginx on Debian-based systems
  apt:
    name: nginx
    state: present
  when: ansible_os_family == "Debian"
```

---

### **Advanced Task: Registering Task Results**

#### **Goal**: Check if a file exists and create it if it doesn’t.

```yaml
- name: Check if a file exists
  stat:
    path: /opt/my_app/config.yml
  register: file_status

- name: Create the file if it doesn’t exist
  copy:
    dest: /opt/my_app/config.yml
    content: "This is a new configuration file."
  when: not file_status.stat.exists
```

---

### **Advanced Task: Delegating Tasks**

#### **Goal**: Run a task on the control node instead of the managed host.

```yaml
- name: Update local inventory file
  lineinfile:
    path: /etc/ansible/hosts
    line: "webserver ansible_host=192.168.1.100"
  delegate_to: localhost
```

---

### **Advanced Task: Using Handlers**

#### **Goal**: Restart a service when a configuration file changes.

```yaml
- name: Update Nginx configuration
  copy:
    src: nginx.conf
    dest: /etc/nginx/nginx.conf
    notify: Restart Nginx

handlers:
  - name: Restart Nginx
    service:
      name: nginx
      state: restarted
```

---

### **Complex Task: Using Roles**

#### **Goal**: Organize tasks into a role for reusability.

**Directory Structure**:
```
roles/
└── webserver/
    ├── tasks/
    │   └── main.yml
    ├── templates/
    │   └── nginx.conf.j2
    └── vars/
        └── main.yml
```

**`roles/webserver/tasks/main.yml`**:
```yaml
- name: Install Nginx
  apt:
    name: nginx
    state: present
    update_cache: yes

- name: Configure Nginx
  template:
    src: nginx.conf.j2
    dest: /etc/nginx/nginx.conf
    notify: Restart Nginx
```

**`roles/webserver/templates/nginx.conf.j2`**:
```nginx
server {
    listen 80;
    server_name {{ server_name }};

    location / {
        root /var/www/html;
        index index.html;
    }
}
```

**`roles/webserver/vars/main.yml`**:
```yaml
server_name: example.com
```

**Playbook**:
```yaml
- name: Configure Web Server
  hosts: webservers
  roles:
    - webserver
```

---

### **Expert-Level Task: Using Dynamic Inventory**

#### **Goal**: Use a dynamic inventory script to fetch hosts from AWS and configure them.

```yaml
- name: Fetch dynamic inventory from AWS
  hosts: all
  tasks:
    - name: Install Nginx on AWS instances
      yum:
        name: nginx
        state: present
```

---

This progression takes you from basic tasks like installing a package to advanced topics like dynamic inventory and roles, offering a comprehensive understanding of Ansible tasks. Let me know if you'd like additional exercises!