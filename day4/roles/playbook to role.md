# 🎓 Hands-On Lab: Converting a Complex Playbook into Modular Ansible Roles

## ✅ Objective

This lab teaches you how to:

* Break down a large monolithic playbook into modular roles
* Create four roles: `webserver`, `database`, `user-management`, and `firewall`
* Deploy a webpage that says "This is my role"
* Manage PostgreSQL database users
* Control access using UFW firewall rules

---

## 🔢 Prerequisites

* Ansible installed (`sudo apt install ansible -y`)
* Linux test system (or localhost)
* Basic understanding of tasks, variables, handlers, and templates

---

## 📃 Step 1: Original Flat Playbook

Create a file `full_stack.yml` with the following content:

```yaml
- name: Deploy full web and database stack
  hosts: localhost
  become: yes
  vars:
    apache_port: 80
    webpage_content: "This is my role"
    users:
      - name: webuser
        shell: /bin/bash
      - name: dbuser
        shell: /bin/bash
    allowed_ports:
      - 22
      - 80
      - 5432
    db_name: myappdb
    db_user: appuser
    db_password: securepass

  tasks:
    - name: Install Apache
      apt:
        name: apache2
        state: present
        update_cache: yes

    - name: Deploy webpage
      copy:
        content: "{{ webpage_content }}"
        dest: /var/www/html/index.html

    - name: Start and enable Apache
      service:
        name: apache2
        state: started
        enabled: yes

    - name: Install PostgreSQL
      apt:
        name: [postgresql, postgresql-contrib, python3-psycopg2]
        state: present
        update_cache: yes

    - name: Ensure PostgreSQL is running
      service:
        name: postgresql
        state: started
        enabled: yes

    - name: Create PostgreSQL database
      become_user: postgres
      postgresql_db:
        name: "{{ db_name }}"

    - name: Create PostgreSQL user
      become_user: postgres
      postgresql_user:
        name: "{{ db_user }}"
        password: "{{ db_password }}"
        priv: "{{ db_name }}=ALL"

    - name: Create system users
      user:
        name: "{{ item.name }}"
        shell: "{{ item.shell }}"
        state: present
      loop: "{{ users }}"

    - name: Allow firewall ports
      ufw:
        rule: allow
        port: "{{ item }}"
      loop: "{{ allowed_ports }}"
```

---

## 📆 Step 2: Create the Roles

```bash
ansible-galaxy init webserver
ansible-galaxy init database
ansible-galaxy init firewall
ansible-galaxy init user-management
```

---

## 🔧 Step 3: Populate Each Role

### webserver/

* `defaults/main.yml`

```yaml
apache_port: 80
webpage_content: "This is my role"
```

* `tasks/main.yml`

```yaml
- name: Install Apache
  apt:
    name: apache2
    state: present
    update_cache: yes

- name: Deploy webpage
  copy:
    content: "{{ webpage_content }}"
    dest: /var/www/html/index.html

- name: Start and enable Apache
  service:
    name: apache2
    state: started
    enabled: yes
```

### database/

* `defaults/main.yml`

```yaml
db_name: myappdb
db_user: appuser
db_password: securepass
```

* `tasks/main.yml`

```yaml
- name: Install PostgreSQL
  apt:
    name: [postgresql, postgresql-contrib, python3-psycopg2]
    state: present
    update_cache: yes

- name: Ensure PostgreSQL is running
  service:
    name: postgresql
    state: started
    enabled: yes

- name: Create PostgreSQL database
  become_user: postgres
  postgresql_db:
    name: "{{ db_name }}"

- name: Create PostgreSQL user
  become_user: postgres
  postgresql_user:
    name: "{{ db_user }}"
    password: "{{ db_password }}"
    priv: "{{ db_name }}=ALL"
```

### user-management/

* `defaults/main.yml`

```yaml
users:
  - name: webuser
    shell: /bin/bash
  - name: dbuser
    shell: /bin/bash
```

* `tasks/main.yml`

```yaml
- name: Create system users
  user:
    name: "{{ item.name }}"
    shell: "{{ item.shell }}"
    state: present
  loop: "{{ users }}"
```

### firewall/

* `defaults/main.yml`

```yaml
allowed_ports:
  - 22
  - 80
  - 5432
```

* `tasks/main.yml`

```yaml
- name: Allow firewall ports
  ufw:
    rule: allow
    port: "{{ item }}"
  loop: "{{ allowed_ports }}"
```

---

## 📌 Step 4: Create the Role-Based Playbook

```yaml
# site.yml
- name: Deploy full stack using roles
  hosts: localhost
  become: yes
  roles:
    - user-management
    - firewall
    - database
    - webserver
```

---

## ▶️ Step 5: Run the Refactored Playbook

```bash
ansible-playbook -i inventory.ini site.yml
```

---

## 🔄 Step 6: Verify Results

```bash
curl http://localhost
sudo systemctl status apache2
sudo systemctl status postgresql
psql -U postgres -c '\l'   # List databases (if you have psql access)
sudo ufw status
getent passwd webuser
gentent passwd dbuser
```

---

## 📊 Summary

| Step         | Result                                                           |
| ------------ | ---------------------------------------------------------------- |
| Original     | Flat, all-in-one playbook with multiple services                 |
| Refactor     | Created 4 modular roles for webserver, database, users, firewall |
| Deployment   | Applied with single playbook in sequence                         |
| Verification | Confirmed running services, ports, users, and webpage            |

---

