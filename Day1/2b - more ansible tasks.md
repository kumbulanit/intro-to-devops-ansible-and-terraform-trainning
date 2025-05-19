Here’s a step-by-step guide focused only on **Ansible tasks**, starting simple and progressing to more advanced features.  

---

### Step 1: **Simple Task – Ping Test**
#### Task: Ensure the target machine is reachable.
```yaml
- name: Test connection to managed nodes
  hosts: all
  tasks:
    - name: Ping the target machine
      ansible.builtin.ping:
```

---

### Step 2: **User Management**
#### Task: Create a new user.
```yaml
- name: Create a user on the target machine
  hosts: all
  become: yes
  tasks:
    - name: Ensure a user 'deployer' exists
      ansible.builtin.user:
        name: deployer
        state: present
        shell: /bin/bash
```

---

### Step 3: **Package Management**
#### Task: Install a package (e.g., Apache).
```yaml
- name: Install Apache Web Server
  hosts: all
  become: yes
  tasks:
    - name: Install Apache
      ansible.builtin.yum:
        name: httpd
        state: present
```

---

### Step 4: **Service Management**
#### Task: Start and enable the Apache service.
```yaml
- name: Manage Apache service
  hosts: all
  become: yes
  tasks:
    - name: Start and enable Apache
      ansible.builtin.service:
        name: httpd
        state: started
        enabled: yes
```

---

### Step 5: **File Copy**
#### Task: Deploy an HTML file to the server.
```yaml
- name: Deploy a static HTML file
  hosts: all
  become: yes
  tasks:
    - name: Copy index.html to web root
      ansible.builtin.copy:
        src: /path/to/index.html
        dest: /var/www/html/index.html
        owner: root
        group: root
        mode: '0644'
```

---

### Step 6: **Using Variables**
#### Task: Make package and file paths configurable.
```yaml
- name: Configure using variables
  hosts: all
  become: yes
  vars:
    apache_package: httpd
    web_root: /var/www/html
  tasks:
    - name: Install Apache using variables
      ansible.builtin.yum:
        name: "{{ apache_package }}"
        state: present

    - name: Copy HTML to web root using variables
      ansible.builtin.copy:
        src: /path/to/index.html
        dest: "{{ web_root }}/index.html"
        owner: root
        group: root
        mode: '0644'
```

---

### Step 7: **Templates**
#### Task: Deploy a dynamic web page using a Jinja2 template.
```yaml
- name: Deploy a dynamic HTML page
  hosts: all
  become: yes
  vars:
    server_name: My Awesome Server
    web_root: /var/www/html
  tasks:
    - name: Deploy HTML using a template
      ansible.builtin.template:
        src: templates/index.html.j2
        dest: "{{ web_root }}/index.html"
        owner: root
        group: root
        mode: '0644'
```

---

### Step 8: **Handlers**
#### Task: Restart Apache only if a configuration changes.
```yaml
- name: Use handlers for service management
  hosts: all
  become: yes
  tasks:
    - name: Deploy configuration file
      ansible.builtin.copy:
        src: /path/to/httpd.conf
        dest: /etc/httpd/conf/httpd.conf
        notify: Restart Apache

  handlers:
    - name: Restart Apache
      ansible.builtin.service:
        name: httpd
        state: restarted
```

---

### Step 9: **Loops**
#### Task: Install multiple packages.
```yaml
- name: Install required packages
  hosts: all
  become: yes
  tasks:
    - name: Install a list of packages
      ansible.builtin.yum:
        name: "{{ item }}"
        state: present
      loop:
        - httpd
        - mariadb-server
        - php
```

---

### Step 10: **Conditional Tasks**
#### Task: Execute a task based on the operating system.
```yaml
- name: Conditional execution based on OS
  hosts: all
  become: yes
  tasks:
    - name: Install Apache on RedHat-based systems
      ansible.builtin.yum:
        name: httpd
        state: present
      when: ansible_os_family == "RedHat"
```

---

### Step 11: **Debugging**
#### Task: Print a variable for debugging.
```yaml
- name: Debugging example
  hosts: all
  tasks:
    - name: Print the IP address of the target machine
      ansible.builtin.debug:
        msg: "The IP address of this host is {{ ansible_default_ipv4.address }}"
```

