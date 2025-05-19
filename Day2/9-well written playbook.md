Exercise to of Well Written playbooks

### **Directory Structure**

```plaintext
.
├── site.yml
├── inventory.ini
├── vars
│   └── server_vars.yml
├── tasks
│   ├── install_nginx.yml
│   ├── install_apache.yml
│   ├── install_mysql.yml
│   └── install_postgresql.yml
├── handlers
│   └── restart_services.yml
└── ansible.cfg
```

### **Inventory File (`inventory.ini`)**

```ini
[web_servers]
localhost ansible_connection=local

[db_servers]
localhost ansible_connection=local

[all:vars]
ansible_user=ubuntu
```

### **Variables File (`vars/server_vars.yml`)**

```yaml
---
packages:
  nginx:
    name: nginx
    state: present
  apache:
    name: apache2
    state: present
  mysql:
    name: mysql-server
    state: present
  postgresql:
    name: postgresql
    state: present

services:
  nginx: nginx
  apache: apache2
  mysql: mysql
  postgresql: postgresql
```

### **Playbook (`site.yml`)**

```yaml
---
- name: Manage Web and Database Servers
  hosts: all
  become: true
  vars_files:
    - vars/server_vars.yml

  tasks:
    - name: Check if nginx is installed
      command: dpkg -l | grep nginx
      register: nginx_check
      ignore_errors: true
      changed_when: false

    - name: Uninstall nginx if already installed
      apt:
        name: "{{ packages.nginx.name }}"
        state: absent
      when: nginx_check.rc == 0

    - name: Install Nginx package
      apt:
        name: "{{ packages.nginx.name }}"
        state: "{{ packages.nginx.state }}"
        update_cache: yes
      notify:
        - Restart nginx

    - name: Check if apache2 is installed
      command: dpkg -l | grep apache2
      register: apache_check
      ignore_errors: true
      changed_when: false

    - name: Uninstall apache2 if already installed
      apt:
        name: "{{ packages.apache.name }}"
        state: absent
      when: apache_check.rc == 0

    - name: Install Apache2 package
      apt:
        name: "{{ packages.apache.name }}"
        state: "{{ packages.apache.state }}"
        update_cache: yes
      notify:
        - Restart apache

    - name: Check if mysql is installed
      command: dpkg -l | grep mysql
      register: mysql_check
      ignore_errors: true
      changed_when: false

    - name: Uninstall mysql if already installed
      apt:
        name: "{{ packages.mysql.name }}"
        state: absent
      when: mysql_check.rc == 0

    - name: Install MySQL package
      apt:
        name: "{{ packages.mysql.name }}"
        state: "{{ packages.mysql.state }}"
        update_cache: yes
      notify:
        - Restart mysql

    - name: Check if postgresql is installed
      command: dpkg -l | grep postgresql
      register: postgresql_check
      ignore_errors: true
      changed_when: false

    - name: Uninstall postgresql if already installed
      apt:
        name: "{{ packages.postgresql.name }}"
        state: absent
      when: postgresql_check.rc == 0

    - name: Install PostgreSQL package
      apt:
        name: "{{ packages.postgresql.name }}"
        state: "{{ packages.postgresql.state }}"
        update_cache: yes
      notify:
        - Restart postgresql

  handlers:
    - name: Restart nginx
      service:
        name: "{{ services.nginx }}"
        state: restarted

    - name: Restart apache
      service:
        name: "{{ services.apache }}"
        state: restarted

    - name: Restart mysql
      service:
        name: "{{ services.mysql }}"
        state: restarted

    - name: Restart postgresql
      service:
        name: "{{ services.postgresql }}"
        state: restarted
```

### **Task Files**

Now, let's create task files for each service. These task files are called from the main playbook `site.yml`.

#### **1. Task File for Installing Nginx (`tasks/install_nginx.yml`)**

```yaml
---
- name: Install Nginx
  apt:
    name: "{{ packages.nginx.name }}"
    state: present
    update_cache: yes
```

#### **2. Task File for Installing Apache (`tasks/install_apache.yml`)**

```yaml
---
- name: Install Apache
  apt:
    name: "{{ packages.apache.name }}"
    state: present
    update_cache: yes
```

#### **3. Task File for Installing MySQL (`tasks/install_mysql.yml`)**

```yaml
---
- name: Install MySQL
  apt:
    name: "{{ packages.mysql.name }}"
    state: present
    update_cache: yes
```

#### **4. Task File for Installing PostgreSQL (`tasks/install_postgresql.yml`)**

```yaml
---
- name: Install PostgreSQL
  apt:
    name: "{{ packages.postgresql.name }}"
    state: present
    update_cache: yes
```

### **Handlers File (`handlers/restart_services.yml`)**

This file defines the handlers for restarting services after installation or uninstallation.

```yaml
---
- name: Restart nginx
  service:
    name: "{{ services.nginx }}"
    state: restarted

- name: Restart apache
  service:
    name: "{{ services.apache }}"
    state: restarted

- name: Restart mysql
  service:
    name: "{{ services.mysql }}"
    state: restarted

- name: Restart postgresql
  service:
    name: "{{ services.postgresql }}"
    state: restarted
```

### **How the Playbook Works**

1. **Check if Package is Installed**: The playbook first checks if each package is installed using the `dpkg -l` command. If the package is found, the playbook will uninstall it before reinstalling it.
   
2. **Uninstall and Reinstall**: If a package is already installed, the playbook removes it and installs it again. This ensures a fresh installation.

3. **Restart Services**: After each package is installed or reinstalled, the playbook triggers handlers to restart the corresponding services (Nginx, Apache, MySQL, PostgreSQL) to apply the changes.

### **Running the Playbook**

1. Ensure that you have Ansible installed on your system and that the directory structure is correct.
2. Run the following command to execute the playbook:

```bash
ansible-playbook site.yml
```

### **Results**

- **Package Management**: The playbook checks, uninstalls, and installs Nginx, Apache, MySQL, and PostgreSQL on your Ubuntu localhost.
- **Service Restart**: It ensures that the services are restarted after installation or reinstallation.
- **Variable Management**: Uses a `vars` file for defining package names and services, making the playbook easy to maintain and scalable.

