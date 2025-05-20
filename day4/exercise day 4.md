# 🎓 1.5-Hour Hands-On Lab: Mastering Ansible Variables, Python, Vault, Roles & Galaxy

## ✅ Objective

By the end of this lab, learners will:

* Manipulate variables using Jinja2 filters
* Use Python logic within Ansible playbooks
* Follow variable best practices
* Secure variables and playbooks using Ansible Vault
* Understand and implement roles with Galaxy integrations

Estimated Duration: **1 hour 30 minutes**

---

## ✅ Prerequisites

* Linux or Ubuntu machine with `sudo` access
* Ansible installed (`sudo apt install ansible -y`)
* Internet access
* Basic understanding of Ansible tasks and YAML

---

## 🔢 Lab Environment Setup

```bash
mkdir -p ~/ansible-lab/vars_demo && cd ~/ansible-lab
cd vars_demo
echo "localhost ansible_connection=local" > inventory.ini
```

---

## 🔍 Section 1: Variables and Python in Ansible

### ✅ Step 1: Jinja Filters for Variable Manipulation

Create a playbook:

```bash
nano jinja_filters.yml
```

```yaml
- name: Jinja Filters Demo
  hosts: localhost
  gather_facts: false
  vars:
    full_name: "john doe"
    users:
      - alice
      - bob
      - charlie
  tasks:
    - name: Capitalize a string
      debug:
        msg: "{{ full_name | title }}"

    - name: Count list elements
      debug:
        msg: "User count is {{ users | length }}"

    - name: Reverse list
      debug:
        msg: "{{ users | reverse }}"
```

Run it:

```bash
ansible-playbook -i inventory.ini jinja_filters.yml
```

---

### ✅ Step 2: Using Python within Playbooks

Create:

```bash
nano python_logic.yml
```

```yaml
- name: Python Expressions in Ansible
  hosts: localhost
  gather_facts: false
  vars:
    a: 4
    b: 6
  tasks:
    - name: Multiply variables
      debug:
        msg: "Result: {{ a * b }}"

    - name: Use condition in expression
      debug:
        msg: >
          {% if a > b %}
            A is greater
          {% else %}
            B is greater or equal
          {% endif %}
```

Run:

```bash
ansible-playbook -i inventory.ini python_logic.yml
```

---

### ✅ Step 3: Best Practices for Variables

Create `group_vars/all.yml`:

```bash
mkdir -p group_vars
echo "site_name: MyWebsite" > group_vars/all.yml
```

Use in a playbook:

```bash
nano var_best_practice.yml
```

```yaml
- name: Use external variables
  hosts: localhost
  gather_facts: false
  tasks:
    - name: Display site name
      debug:
        msg: "Welcome to {{ site_name }}"
```

Run:

```bash
ansible-playbook -i inventory.ini var_best_practice.yml
```

---

## 🔐 Section 2: Securing Credentials with Ansible Vault

### ✅ Step 4: Creating Vault-Encrypted Variables

```bash
ansible-vault create group_vars/all/vault.yml
```

Paste:

```yaml
vault_db_password: secret123
```

Use it in a playbook:

```bash
nano vault_demo.yml
```

```yaml
- name: Secure vars with Vault
  hosts: localhost
  vars_files:
    - group_vars/all/vault.yml
  tasks:
    - name: Show secured password
      debug:
        msg: "Password is {{ vault_db_password }}"
```

Run:

```bash
ansible-playbook -i inventory.ini vault_demo.yml --ask-vault-pass
```

---

### ✅ Step 5: Encrypting a Playbook

```bash
ansible-vault encrypt vault_demo.yml
```

View encrypted file:

```bash
cat vault_demo.yml
```

Run it:

```bash
ansible-playbook -i inventory.ini vault_demo.yml --ask-vault-pass
```

---

## 🏠 Section 3: Roles and Galaxy

### ✅ Step 6: Why We Need Roles

Create a flat playbook first:

```bash
nano web.yml
```

```yaml
- name: Install and start Apache
  hosts: localhost
  become: yes
  tasks:
    - name: Install Apache
      apt:
        name: apache2
        state: present
        update_cache: yes
    - name: Start Apache
      service:
        name: apache2
        state: started
```

Now create a role:

```bash
ansible-galaxy init apache_role
```

Move the logic to `apache_role/tasks/main.yml`

### Step 7: Role Directory Structure

View:

```bash
tree apache_role
```

Review:

* `tasks/`
* `handlers/`
* `defaults/`
* `templates/`
* `meta/`

### Step 8: Using Roles

Create `site.yml`:

```yaml
- name: Apply Apache Role
  hosts: localhost
  become: yes
  roles:
    - apache_role
```

Run:

```bash
ansible-playbook -i inventory.ini site.yml
```

### Step 9: Role Default Variables

Add `apache_port: 80` in `defaults/main.yml`
Use it in a template:

```jinja
<VirtualHost *:{{ apache_port }}>
    DocumentRoot /var/www/html
</VirtualHost>
```

### Step 10: Converting a Playbook to a Role

Use the same steps: extract variables to `defaults/`, tasks to `tasks/`, handlers, etc.

---

## 🌐 Section 4: Galaxy Roles

### ✅ Step 11: Explore and Install from Galaxy

```bash
nano requirements.yml
```

```yaml
- src: geerlingguy.apache
  version: 3.1.0
- src: geerlingguy.mysql
  version: 3.3.0
```

Install:

```bash
ansible-galaxy install -r requirements.yml
```

### Step 12: Run Galaxy Role

Create playbook:

```bash
nano galaxy_playbook.yml
```

```yaml
- name: Use Galaxy Roles
  hosts: localhost
  become: yes
  vars:
    mysql_root_password: mypass
    mysql_databases:
      - name: mydb
  roles:
    - geerlingguy.apache
    - geerlingguy.mysql
```

Run:

```bash
ansible-playbook -i inventory.ini galaxy_playbook.yml
```

---

## 📊 Summary

| Topic          | Coverage                                             |
| -------------- | ---------------------------------------------------- |
| Jinja Filters  | String, list, math filters                           |
| Python Logic   | `if`, math ops, loops                                |
| Vault          | Encrypted variables and playbooks                    |
| Roles          | Created manually and from Galaxy                     |
| Best Practices | Used `group_vars`, default variables, reusable tasks |

E