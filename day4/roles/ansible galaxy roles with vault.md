# 🎓 Hands-On Lab: Running Roles from Ansible Galaxy with Ansible Vault

## ✅ Objective

This comprehensive lab teaches you to:

* Discover and install verified roles from Ansible Galaxy
* Deploy a full stack: system users, a MySQL database, and a web server
* Secure sensitive data using Ansible Vault
* Customize role variables
* Extend and validate the deployment

---

## ✅ Prerequisites

* Ubuntu/Linux host or VM with `sudo` access
* Ansible installed (`sudo apt install ansible -y`)
* Python 3 and `pip` installed
* Internet connection

---

## 🔍 Step 1: Set Up Your Project Workspace

```bash
mkdir -p ~/ansible-galaxy-lab && cd ~/ansible-galaxy-lab
mkdir group_vars roles templates
```

Create the inventory:

```bash
echo "localhost ansible_connection=local" > inventory.ini
```

---

## 🌐 Step 2: Use a `requirements.yml` to Install Roles from Galaxy

Create `requirements.yml`:

```yaml
- src: geerlingguy.mysql
  version: 3.3.0
- src: geerlingguy.apache
  version: 3.1.0
- src: bertvv.users
  version: 2.3.0
```

Install them:

```bash
ansible-galaxy install -r requirements.yml
```

Confirm roles are installed:

```bash
ansible-galaxy list
```

---

## 🔐 Step 3: Create and Use Ansible Vault

### Create a vault file for sensitive DB credentials:

```bash
ansible-vault create group_vars/all/vault.yml
```

Paste and save:

```yaml
vault_mysql_root_password: "rootpass"
vault_db_user: "secureuser"
vault_db_password: "securepass"
```

Create a non-encrypted `group_vars/all.yml` to reference the vault:

```yaml
mysql_root_password: "{{ vault_mysql_root_password }}"
mysql_users:
  - name: "{{ vault_db_user }}"
    password: "{{ vault_db_password }}"
    priv: "mysite_db.*:ALL"
    host: localhost

mysql_databases:
  - name: mysite_db

apache_vhosts:
  - servername: localhost
    documentroot: /var/www/html
    extra_parameters: |
      DirectoryIndex index.html

users:
  - name: webadmin
    shell: /bin/bash
    groups: ["www-data"]
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
```

---

## 📄 Step 4: Create the Main Playbook

```yaml
# site.yml
- name: Galaxy Stack Deployment
  hosts: localhost
  become: yes
  vars_files:
    - group_vars/all/vault.yml
  roles:
    - bertvv.users
    - geerlingguy.mysql
    - geerlingguy.apache
```

---

## 📁 Step 5: Add Custom Web Content

```bash
echo "<h1>Welcome to My Secure Galaxy-powered Website</h1>" | sudo tee /var/www/html/index.html
```

---

## ▶️ Step 6: Run the Playbook (with Vault Password Prompt)

```bash
ansible-playbook -i inventory.ini site.yml --ask-vault-pass
```

If successful, this will:

* Create user `webadmin`
* Install and configure MySQL with a secured database and user
* Serve a custom Apache web page

---

## 🔍 Step 7: Validate the Deployment

### 🔧 Apache

```bash
curl http://localhost
sudo systemctl status apache2
```

### 🔐 Users

```bash
getent passwd webadmin
```

### 🗄️ MySQL

```bash
mysql -u root -p -e "SHOW DATABASES;"
```

### 🔐 Vault Content Test

```bash
ansible-vault view group_vars/all/vault.yml
```

---

## 🧪 Step 8: Practice Challenges

### Challenge 1: Add another database and user

* Add a new `mysql_user` and `mysql_database` in `group_vars/all.yml`

### Challenge 2: Restrict Apache to a different port

* Add `apache_listen_port: 8080` and update your firewall (if needed)

### Challenge 3: Add another system user with a different shell

* Append to the `users:` list in `group_vars/all.yml`

### Challenge 4: Encrypt the entire `group_vars/all.yml` with Vault

```bash
ansible-vault encrypt group_vars/all.yml
```

Then remove `vars_files:` and replace with:

```yaml
vars_files:
  - group_vars/all.yml
```

---

## ✅ Summary

| Step                     | Outcome                                        |
| ------------------------ | ---------------------------------------------- |
| Install Galaxy roles     | Used `requirements.yml` with version pinning   |
| Create users             | `bertvv.users` role                            |
| Deploy MySQL + DB + user | `geerlingguy.mysql` with Vault integration     |
| Serve custom site        | `geerlingguy.apache` with `index.html` content |
| Protect secrets          | `ansible-vault` used for root/db credentials   |

