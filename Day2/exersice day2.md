### **Practical Exercise to Test Ansible Concepts**

---

### **Exercise Tasks**

---

#### **Task 1: Ansible Static Inventory**

1. **Define Hosts and Groups**  
   Create a file called `hosts` and define two groups: `webservers` and `databases`. Assign hosts to each group with their respective IP addresses.

2. **Host and Group Variables**  
   Define variables for the `webservers` group and one specific variable for a host within the `databases` group.

3. **Groups of Groups**  
   Create a parent group called `all_servers` that contains both `webservers` and `databases` groups.

4. **Default Groups**  
   Create a group `all` and use it to assign default variables that should apply to all hosts in the inventory.

---

#### **Task 2: YAML Concepts**

1. **YAML Gotchas**  
   Define a variable `server_info` with the correct YAML syntax, ensuring no syntax error occurs with special characters, indentation, and lists.

2. **YAML Dictionary**  
   Define a dictionary for server `server_info` with keys for `hostname`, `ip_address`, and `os`.

3. **YAML List**  
   Define a list `servers` containing two servers: `web1` and `web2`.

4. **YAML List of Dictionaries**  
   Define a list `server_details`, each item containing a dictionary with `name`, `ip`, and `os` properties.

5. **YAML Alternate Format**  
   Define an alternate YAML format for servers that uses inline dictionaries.

6. **Relationship to JSON**  
   Provide the JSON representation of the `server_info` YAML dictionary.

---

#### **Task 3: Ansible Ad-hoc Commands**

1. **Install Nginx on Web Servers**  
   Use an ad-hoc command to install `nginx` on the `webservers` group.

2. **Check if MySQL is Installed**  
   Use an ad-hoc command to check if `mysql` is installed on the `databases` group.

3. **Create a New User and Group**  
   Use an ad-hoc command to create a user `alice` and assign them to the `sudo` group.

4. **Gather Facts on All Hosts**  
   Use an ad-hoc command to gather system facts from all hosts.

5. **Uninstall Nginx**  
   Use an ad-hoc command to uninstall `nginx` from all hosts in the `webservers` group if it is already installed.

6. **Run Parallel Shell Commands**  
   Use an ad-hoc command to run `hostname` in parallel on all hosts.

7. **Ensure MySQL is Running**  
   Use an ad-hoc command to ensure that the `mysql` service is started on the `databases` group.

8. **Ad-Hoc Cheat Sheet**  
   Write out a cheat sheet of common ad-hoc command syntax for package management, user management, and service management.

---

#### **Task 4: Writing a Simple Playbook**

1. **Elements of a Well-Written Playbook**  
   Write a playbook that installs `nginx` and `mysql-server` on `webservers` and `databases` groups, respectively.

2. **A Well-Written Ansible Play**  
   Write a playbook that checks if `nginx` and `mysql-server` are installed, and if not, installs them.

3. **Using Include Files for Tasks**  
   Write a playbook that includes two separate task files: one for installing `nginx` and one for installing `mysql-server`.

4. **A Well-Written Ansible Variable File**  
   Create a variables file `vars.yml` containing variables for package names (nginx, mysql-server) and use it in a playbook to install the packages.

5. **A Well-Written Ansible Inventory File**  
   Create a full inventory file that defines the `webservers` and `databases` groups, along with specific host IP addresses.

---

### **Answers for the Exercise**

---

#### **Task 1: Ansible Static Inventory**

1. **Define Hosts and Groups (`hosts` file)**

```ini
[webservers]
web1 ansible_host=192.168.1.10
web2 ansible_host=192.168.1.11

[databases]
db1 ansible_host=192.168.1.12
db2 ansible_host=192.168.1.13

[all_servers:children]
webservers
databases

[all:vars]
ansible_user=ubuntu
```

2. **Host and Group Variables**

```ini
[webservers:vars]
web_port=80

[databases:vars]
db_name=production
```

3. **Groups of Groups**  
   Already defined in the inventory file, `all_servers` includes both `webservers` and `databases`.

4. **Default Groups**  
   The `[all:vars]` section is an example of default group variables that apply to all hosts.

---

#### **Task 2: YAML Concepts**

1. **YAML Gotchas**  
   The indentation and character handling in YAML must be correct. The following is valid:

```yaml
server_info:
  hostname: webserver1
  ip_address: 192.168.1.10
  os: ubuntu
```

2. **YAML Dictionary**

```yaml
server_info:
  hostname: webserver1
  ip_address: 192.168.1.10
  os: ubuntu
```

3. **YAML List**

```yaml
servers:
  - web1
  - web2
```

4. **YAML List of Dictionaries**

```yaml
server_details:
  - name: web1
    ip: 192.168.1.10
    os: ubuntu
  - name: web2
    ip: 192.168.1.11
    os: ubuntu
```

5. **YAML Alternate Format**

```yaml
servers: [web1, web2]
```

6. **Relationship to JSON**

```json
{
  "server_info": {
    "hostname": "webserver1",
    "ip_address": "192.168.1.10",
    "os": "ubuntu"
  }
}
```

---

#### **Task 3: Ansible Ad-hoc Commands**

1. **Install Nginx on Web Servers**

```bash
ansible webservers -m apt -a "name=nginx state=present" --become
```

2. **Check if MySQL is Installed**

```bash
ansible databases -m shell -a "dpkg -l | grep mysql" --become
```

3. **Create a New User and Group**

```bash
ansible all -m user -a "name=alice groups=sudo state=present" --become
```

4. **Gather Facts on All Hosts**

```bash
ansible all -m setup
```

5. **Uninstall Nginx**

```bash
ansible webservers -m apt -a "name=nginx state=absent" --become
```

6. **Run Parallel Shell Commands**

```bash
ansible all -m shell -a "hostname"
```

7. **Ensure MySQL is Running**

```bash
ansible databases -m service -a "name=mysql state=started enabled=yes" --become
```

8. **Ad-Hoc Cheat Sheet**  
   **Package Management:**
   - Install: `ansible all -m apt -a "name=nginx state=present" --become`
   - Remove: `ansible all -m apt -a "name=nginx state=absent" --become`
   
   **User Management:**
   - Create: `ansible all -m user -a "name=alice groups=sudo state=present" --become`
   
   **Service Management:**
   - Start: `ansible all -m service -a "name=nginx state=started" --become`
   - Stop: `ansible all -m service -a "name=nginx state=stopped" --become`

---

#### **Task 4: Writing a Simple Playbook**

1. **Elements of a Well-Written Playbook**

```yaml
- name: Install Nginx and MySQL
  hosts: all
  tasks:
    - name: Install nginx
      apt:
        name: nginx
        state: present
      become: yes

    - name: Install mysql-server
      apt:
        name: mysql-server
        state: present
      become: yes
```

2. **A Well-Written Ansible Play**

```yaml
- name: Ensure nginx and mysql are installed
  hosts: all
  tasks:
    - name: Install nginx
      apt:
        name: nginx
        state: present
      when: ansible_facts.packages['nginx'] is not defined

    - name: Install mysql-server
      apt:
        name: mysql-server
        state: present
      when: ansible_facts.packages['mysql-server'] is not defined
```

3. **Using Include Files for Tasks**

```yaml
- name: Install packages
  hosts: all
  tasks:
    - include_tasks: install_nginx.yml
    - include_tasks: install_mysql.yml


```

4. **A Well-Written Ansible Variable File**

```yaml
# vars.yml
packages:
  - nginx
  - mysql-server
```

```yaml
# playbook.yml
- name: Install Packages
  hosts: all
  vars_files:
    - vars.yml
  tasks:
    - name: Install packages
      apt:
        name: "{{ item }}"
        state: present
      loop: "{{ packages }}"
      become: yes
```

5. **A Well-Written Ansible Inventory File**

```ini
[webservers]
web1 ansible_host=192.168.1.10
web2 ansible_host=192.168.1.11

[databases]
db1 ansible_host=192.168.1.12
db2 ansible_host=192.168.1.13

[all_servers:children]
webservers
databases
```

---
