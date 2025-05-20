# 🎓 Hands-On Lab: Running Roles from Ansible Galaxy

## ✅ Objective

In this lab, you will:

* Explore and install roles from Ansible Galaxy
* Use verified community roles
* Deploy a complete stack: users, database, and a website

---

## ✅ Prerequisites

* Linux host or VM with Ansible installed
* Internet connection
* Python 3 and `pip` installed
* User with `sudo` privileges

---

## 🔍 Step 1: Create the Project Directory

```bash
mkdir ~/ansible-galaxy-lab && cd ~/ansible-galaxy-lab
```

Create your inventory:

```bash
echo "localhost ansible_connection=local" > inventory.ini
```

---

## 🌐 Step 2: Use a `requirements.yml` File to Install Galaxy Roles

Create the file:

```bash
nano requirements.yml
```

Paste the following:

```yaml
- src: geerlingguy.mysql
  version: 3.3.0
- src: geerlingguy.apache
  version: 3.1.0
- src: bertvv.users
  version: 2.3.0
```

Install the roles:

```bash
ansible-galaxy install -r requirements.yml
```

> Roles are installed into `~/.ansible/roles` by default.

---

## 📄 Step 3: Create the Playbook

```bash
nano site.yml
```

Paste the following:

```yaml
- name: Deploy full stack using Galaxy roles
  hosts: localhost
  become: yes
  vars:
    users:
      - name: webadmin
        shell: /bin/bash
        groups: ["www-data"]
        sudo: ['ALL=(ALL) NOPASSWD:ALL']

    mysql_root_password: "rootpass"
    mysql_databases:
      - name: mysite_db
    mysql_users:
      - name: myuser
        host: localhost
        password: "mypass"
        priv: "mysite_db.*:ALL"

    apache_vhosts:
      - servername: localhost
        documentroot: "/var/www/html"
        extra_parameters: |
          DirectoryIndex index.html

  roles:
    - role: bertvv.users
    - role: geerlingguy.mysql
    - role: geerlingguy.apache
```

---

## 🔧 Step 4: Add a Website File

```bash
echo "<h1>This is my Galaxy-powered website!</h1>" | sudo tee /var/www/html/index.html
```

---

## ▶️ Step 5: Run the Playbook

```bash
ansible-playbook -i inventory.ini site.yml
```

Expected outcomes:

* MySQL is installed and secured
* A user `myuser` with `mysite_db` database is created
* Apache is installed and configured
* Web page is accessible at `http://localhost`
* System user `webadmin` is created with sudo access

---

## 🔄 Step 6: Verify the Deployment

### 🔢 Verify Users

```bash
getent passwd webadmin
```

### 🔢 Verify MySQL

```bash
mysql -u root -prootpass -e "SHOW DATABASES;"
```

### 🔢 Verify Apache and Web Page

```bash
curl http://localhost
```

You should see:

```
<h1>This is my Galaxy-powered website!</h1>
```

---

## 📊 Summary

| Task            | Outcome                                           |
| --------------- | ------------------------------------------------- |
| Installed roles | Used `ansible-galaxy install -r requirements.yml` |
| Created users   | `bertvv.users` role                               |
| Deployed MySQL  | `geerlingguy.mysql` with user and DB              |
| Hosted website  | `geerlingguy.apache` with vhost                   |

