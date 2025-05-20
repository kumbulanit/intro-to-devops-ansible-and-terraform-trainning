# 🎓 Hands-On Lab: Creating and Using Ansible Roles

## ✅ Objective

By the end of this lab, you will:

* Understand how to create and structure an Ansible role
* Convert a flat playbook into a modular role
* Use the role in a playbook
* Override default variables
* Create a complex role with dependencies

---

## 🔍 Step 1: Setup Your Lab Directory

```bash
mkdir ~/ansible-role-lab && cd ~/ansible-role-lab
```

Create an inventory:

```bash
echo "localhost ansible_connection=local" > inventory.ini
```

---

## 🔧 Step 2: Create Roles

```bash
ansible-galaxy init apache
ansible-galaxy init firewall
```

This creates two roles with structure:

```
roles/
├── apache/
└── firewall/
```

---

## 📃 Step 3: Define Default Variables

### apache/defaults/main.yml

```yaml
apache_port: 80
```

### firewall/defaults/main.yml

```yaml
allowed_ports:
  - 22
  - 80
```

---

## 🔧 Step 4: Create Role Tasks

### apache/tasks/main.yml

```yaml
- name: Install Apache
  apt:
    name: apache2
    state: present
    update_cache: yes

- name: Ensure Apache is started
  service:
    name: apache2
    state: started
    enabled: yes

- name: Configure Apache port
  template:
    src: apache.conf.j2
    dest: /etc/apache2/sites-enabled/000-default.conf
  notify: restart apache
```

### firewall/tasks/main.yml

```yaml
- name: Allow required ports with UFW
  ufw:
    rule: allow
    port: "{{ item }}"
  loop: "{{ allowed_ports }}"
```

---

## 🔧 Step 5: Create a Handler

### apache/handlers/main.yml

```yaml
- name: restart apache
  service:
    name: apache2
    state: restarted
```

---

## 📄 Step 6: Create a Template

### apache/templates/apache.conf.j2

```jinja
<VirtualHost *:{{ apache_port }}>
    DocumentRoot /var/www/html
</VirtualHost>
```

---

## 🔠 Step 7: Define Dependencies

### apache/meta/main.yml

```yaml
dependencies:
  - role: firewall
```

---

## 📄 Step 8: Create a Playbook

Create `site.yml` in the root folder:

```yaml
- name: Deploy Apache with Firewall
  hosts: localhost
  become: yes
  roles:
    - apache
```

---

## 🔄 Step 9: Run the Playbook

```bash
ansible-playbook -i inventory.ini site.yml
```

You should see tasks being executed from both `firewall` and `apache` roles due to the dependency.

---

## 🔍 Step 10: Verify the Deployment

### 🔢 Check Apache Service Status

```bash
sudo systemctl status apache2
```

Look for `active (running)` status.

### 🔢 Verify UFW Rules

```bash
sudo ufw status
```

Ensure ports `22` and `80` are allowed.

### 🔢 Test Apache Response

```bash
curl http://localhost
```

You should see the default Apache welcome page or its HTML content.

### 🔢 Verify Configuration File

```bash
cat /etc/apache2/sites-enabled/000-default.conf
```

Ensure it reflects the `apache_port` value from the role.

---

## 📊 Summary

| Task                   | Outcome                                                            |
| ---------------------- | ------------------------------------------------------------------ |
| Create roles           | `apache` and `firewall` roles created                              |
| Add tasks and handlers | Installed and configured Apache, allowed UFW ports                 |
| Add variables          | Used `defaults/main.yml` to parameterize roles                     |
| Add templates          | Dynamic Apache configuration with port variable                    |
| Define dependencies    | `apache` depends on `firewall` role                                |
| Use role in playbook   | Only `apache` needs to be called; it triggers `firewall`           |
| Verify deployment      | Used `systemctl`, `ufw`, `curl`, and file checks to validate setup |



