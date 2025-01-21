### **Ad-hoc Commands**

#### **Simple Commands**

1. **Ping the host:**

   
```bash

   ansible all -i ~/inventory -m ping
```

2. **Gather facts:**

   
```bash

   ansible all -i ~/inventory -m setup
```

3. **Display the current date and time:**
   
```bash
   ansible all -i ~/inventory -a "date"
```

4. **Uptime of the system:**
   
```bash
   ansible all -i ~/inventory -a "uptime"
```

---

#### **Intermediate Commands**
5. **Create a file:**
   
```bash
   ansible all -i ~/inventory -m file -a "path=/tmp/ansible_test_file state=touch"
```

6. **Install a package (e.g., curl):**
   
```bash
   ansible all -i ~/inventory -m apt -a "name=curl state=present update_cache=yes"
```

7. **Remove a package:**
   
```bash
   ansible all -i ~/inventory -m apt -a "name=curl state=absent"
```

8. **Restart a service (e.g., ssh):**
   
```bash
   ansible all -i ~/inventory -m service -a "name=ssh state=restarted"
```

9. **Create a directory:**
   
```bash
   ansible all -i ~/inventory -m file -a "path=/tmp/ansible_test_dir state=directory"
```

10. **Change file permissions:**
    
```bash
    ansible all -i ~/inventory -m file -a "path=/tmp/ansible_test_file mode=0644"
```

---

#### **Advanced Commands**
11. **Copy a file to the target:**
    
```bash
    ansible all -i ~/inventory -m copy -a "src=/etc/hosts dest=/tmp/hosts_copy"
```

12. **Run a command with elevated privileges:**
    
```bash
    ansible all -i ~/inventory -b -a "apt update"
```

13. **Fetch a file from the target:**
    
```bash
    ansible all -i ~/inventory -m fetch -a "src=/tmp/hosts_copy dest=~/hosts_backup flat=yes"
```

14. **Execute a script on the target:**
    
```bash
    ansible all -i ~/inventory -m script -a "/path/to/your/script.sh"
```

15. **Set environment variables for a command:**
    
```bash
    ansible all -i ~/inventory -a "echo $MY_VAR" -e "MY_VAR=HelloWorld"
```

---

#### **Very Advanced Commands**
16. **Create a user:**
    
```bash
    ansible all -i ~/inventory -m user -a "name=ansible_user state=present"
```

17. **Change the password of a user:**
    
```bash
    ansible all -i ~/inventory -m user -a "name=ansible_user password={{ 'mypassword' | password_hash('sha512') }}"
```

18. **Manage firewall rules:**
    
```bash
    ansible all -i ~/inventory -m ufw -a "rule=allow port=80 proto=tcp"
```

19. **Install multiple packages:**
    
```bash
    ansible all -i ~/inventory -m apt -a "name='git,htop,wget' state=present update_cache=yes"
```

20. **Generate and deploy SSH keys:**
    
```bash
    ansible all -i ~/inventory -m authorized_key -a "user={{ ansible_user }} key='{{ lookup('file', '~/.ssh/id_rsa.pub') }}'"
```

21. **Run multiple commands in one task:**
    
```bash
    ansible all -i ~/inventory -a "sh -c 'echo \"Hello from Ansible\" > /tmp/hello.txt && cat /tmp/hello.txt'"
```

22. **Schedule a cron job:**
    
```bash
    ansible all -i ~/inventory -m cron -a "name='daily_cleanup' minute=0 hour=2 job='/usr/bin/find /tmp -type f -mtime +7 -delete'"
```

23. **Gather specific facts (e.g., IP address):**
    
```bash
    ansible all -i ~/inventory -m setup -a "filter=ansible_default_ipv4"
```

---

### **Testing and Practice**
- Use these commands to practice Ansible operations on your localhost.
- Gradually move from basic commands to advanced ones.
- Combine commands to create complex automation scenarios.

---

### **Cleanup**
After testing, clean up the generated files and directories:
bash
ansible all -i ~/inventory -a "rm -rf /tmp/ansible_test_file /tmp/ansible_test_dir /tmp/hosts_copy /tmp/hello.txt"




## **1. Parallel Shell Commands**

### **Ad-Hoc Examples**

#### **1. Simple Parallel Command Execution**
Run the uptime command across localhost:
```bash
ansible localhost -a "uptime"
```

#### **2. Parallel Execution with Forks**
Limit the number of parallel tasks to 2:
```bash
ansible localhost -a "uptime" -f 2
```

#### **3. Run Command with Sudo**
Execute a command as root using --become:
```bash
ansible localhost -a "apt update" --become
```

#### **4. Run Command with Custom Environment Variables**
Pass an environment variable to the command:
```bash
ansible localhost -a "echo $MY_ENV_VAR" -e "MY_ENV_VAR=HelloWorld"
```

#### **5. Run Multiple Commands**
Use ; to chain commands together:
```bash
ansible localhost -a "uptime; df -h"
```

#### **6. Parallel Commands with File Operations**
Run file copy operation and a service restart simultaneously:
```bash
ansible localhost -a "cp /tmp/testfile /etc/testfile; systemctl restart nginx" -f 2
```

#### **7. Running Shell Scripts in Parallel**
Execute a shell script on localhost:
```bash
ansible localhost -a "/path/to/script.sh" -f 2
```

#### **8. Run Command with Custom Modules in Parallel**
Execute a custom module (e.g., apt) in parallel:
```bash
ansible localhost -m apt -a "name=vim state=present" -f 3 --become
```

---

### **Playbook Examples**

#### **1. Run Basic Commands in Parallel**
```yaml
---
- name: Run uptime in parallel
  hosts: localhost
  tasks:
    - name: Check uptime
      command: uptime

```
#### **2. Run Commands with Custom Forks**
```yaml
---
- name: Run commands in parallel with custom forks
  hosts: localhost
  tasks:
    - name: List files
      command: ls
      fork: 3
```

#### **3. Run Commands with Sudo Privileges**
```yaml
---
- name: Run commands with sudo
  hosts: localhost
  become: true
  tasks:
    - name: Update apt cache
      command: apt update
```

#### **4. Run Commands with Environment Variables**
```yaml
---
- name: Execute commands with environment variables
  hosts: localhost
  tasks:
    - name: Print environment variable
      command: echo $MY_ENV_VAR
      environment:
        MY_ENV_VAR: HelloWorld
```

#### **5. Run Multiple Tasks Simultaneously**
```yaml
---
- name: Run multiple tasks in parallel
  hosts: localhost
  tasks:
    - name: Check uptime
      command: uptime
    - name: List files
      command: ls
```

#### **6. Run Complex Command Sequences**
```yaml
---
- name: Run complex commands
  hosts: localhost
  tasks:
    - name: Clean apt cache
      command: apt clean
    - name: Remove unused dependencies
      command: apt autoremove
```

#### **7. Run Commands Across Different Hosts (if applicable)**
```yaml
---
- name: Run commands across different hosts in parallel
  hosts: localhost
  tasks:
    - name: Check system status
      command: uptime
```

#### **8. Run Multiple Service Restarts in Parallel**
```yaml
---
- name: Restart multiple services in parallel
  hosts: localhost
  tasks:
    - name: Restart nginx
      service:
        name: nginx
        state: restarted
    - name: Restart apache2
      service:
        name: apache2
        state: restarted
```

---

## **2. Managing Packages**

### **Ad-Hoc Examples**

#### **1. Install a Package**
```bash
ansible localhost -m apt -a "name=nginx state=present" --become
```

#### **2. Remove a Package**
```bash
ansible localhost -m apt -a "name=nginx state=absent" --become
```

#### **3. Upgrade a Package**
```bash
ansible localhost -m apt -a "name=nginx state=latest" --become
```

#### **4. Install Multiple Packages**
```bash
ansible localhost -m apt -a "name=nginx,curl state=present" --become
```

#### **5. Install Package with Specific Version**
```bash
ansible localhost -m apt -a "name=nginx=1.18.0-0ubuntu1 state=present" --become
```

#### **6. Install Package and Ensure Dependencies**
```bash
ansible localhost -m apt -a "name=nginx state=present update_cache=yes" --become
```

#### **7. Reinstall a Package**
```bash
ansible localhost -m apt -a "name=nginx state=reinstalled" --become
```

#### **8. Change Configuration File of a Package**
```bash
ansible localhost -m copy -a "src=/tmp/nginx.conf dest=/etc/nginx/nginx.conf" --become
```

---

### **Playbook Examples**

#### **1. Install a Package**
```yaml
---
- name: Install nginx
  hosts: localhost
  become: true
  tasks:
    - name: Install nginx
      apt:
        name: nginx
        state: present
```

#### **2. Remove Unwanted Packages**
```yaml
---
- name: Remove nginx
  hosts: localhost
  become: true
  tasks:
    - name: Remove nginx
      apt:
        name: nginx
        state: absent
```

#### **3. Install Multiple Packages**
```yaml
---
- name: Install nginx and curl
  hosts: localhost
  become: true
  tasks:
    - name: Install nginx
      apt:
        name: nginx
        state: present
    - name: Install curl
      apt:
        name: curl
        state: present
```

#### **4. Upgrade All Packages**
```yaml
---
- name: Upgrade all packages
  hosts: localhost
  become: true
  tasks:
    - name: Upgrade all installed packages
      apt:
        upgrade: dist
```

#### **5. Install Specific Version of a Package**
```yaml
---
- name: Install a specific version of nginx
  hosts: localhost
  become: true
  tasks:
    - name: Install nginx version 1.18
      apt:
        name: nginx=1.18.0-0ubuntu1
        state: present

```
#### **6. Install Packages with Update Cache**
```yaml
---
- name: Install nginx with cache update
  hosts: localhost
  become: true
  tasks:
    - name: Install nginx with cache update
      apt:
        name: nginx
        state: present
        update_cache: yes
```

#### **7. Reinstall a Package**
```yaml
---
- name: Reinstall nginx
  hosts: localhost
  become: true
  tasks:
    - name: Reinstall nginx
      apt:
        name: nginx
        state: reinstalled
```

#### **8. Apply Configuration Changes**
```yaml
---
- name: Apply nginx configuration changes
  hosts: localhost
  become: true
  tasks:
    - name: Upload nginx config
      copy:
        src: /path/to/nginx.conf
        dest: /etc/nginx/nginx.conf
    - name: Restart nginx
      service:
        name: nginx
        state: restarted
```

---

## **3. Managing Users and Groups**

### **Ad-Hoc Examples**

#### **1. Add a User**
```bash
ansible localhost -m user -a "name=johndoe state=present" --become
```

#### **2. Add a Group**
```bash
ansible localhost -m group -a "name=devops state=present" --become
```

#### **3. Add a User to a Group**
```bash
ansible localhost -m user -a "name=johndoe groups=devops append=yes" --become
```

#### **4. Remove a User**
```bash
ansible localhost -m user -a "name=johndoe state=absent" --become
```

#### **5. Change User Password**
```bash
ansible localhost -m user -a "name=johndoe password={{ 'newpassword' | password_hash('sha512') }}" --become
```

#### **6. Set User as Sudoer**
```bash
ansible localhost -m user -a "name=johndoe groups=sudo append=yes" --become
```

#### **7. Remove a Group**
```bash
ansible localhost -m group -a "name=devops state=absent" --become
```

#### **8. Set Expiry Date for User**
```bash
ansible localhost -m user -a "name=johndoe expire=2025-12-31
```
" --become


---

### **Playbook Examples**

#### **1. Create a User**
```yaml
---
- name: Add johndoe user
  hosts: localhost
  become: true
  tasks:
    - name: Add user johndoe
      user:
        name: johndoe
        state: present
```

#### **2. Create a Group**
```yaml
---
- name: Add devops group
  hosts: localhost
  become: true
  tasks:
    - name: Add group devops
      group:
        name: devops
        state: present
```

#### **3. Add a User to a Group**
```yaml
---
- name: Add johndoe to devops group
  hosts: localhost
  become: true
  tasks:
    - name: Add johndoe to devops group
      user:
        name: johndoe
        groups: devops
        append: yes
```

#### **4. Remove a User**
```yaml
---
- name: Remove johndoe user
  hosts: localhost
  become: true
  tasks:
    - name: Remove johndoe
      user:
        name: johndoe
        state: absent
```

#### **5. Change User Password**
```yaml
---
- name: Change johndoe's password
  hosts: localhost
  become: true
  tasks:
    - name: Change password for johndoe
      user:
        name: johndoe
        password: "{{ 'newpassword' | password_hash('sha512') }}"
```

#### **6. Add User to Sudoers Group**
```yaml
---
- name: Add johndoe to sudoers group
  hosts: localhost
  become: true
  tasks:
    - name: Add johndoe to sudoers
      user:
        name: johndoe
        groups: sudo
        append: yes

```
#### **7. Remove Group**
```yaml
---
- name: Remove devops group
  hosts: localhost
  become: true
  tasks:
    - name: Remove devops group
      group:
        name: devops
        state: absent
```

#### **8. Set User Expiry**
```yaml
---
- name: Set expiry for johndoe
  hosts: localhost
  become: true
  tasks:
    - name: Set expiry for johndoe
      user:
        name: johndoe
        expire: 2025-12-31
```

---

## **4. Gathering Facts**

### **Ad-Hoc Examples**

#### **1. Gather Facts for a Host**
```bash
ansible localhost -m setup
```

#### **2. Gather Specific Facts**
```bash
ansible localhost -m setup -a "filter=ansible_distribution"
```

#### **3. Filter Facts for IP Addresses**
```bash
ansible localhost -m setup -a "filter=ansible_all_ipv4_addresses"
```

#### **4. Run Without Gathering Facts**
```bash
ansible localhost -m ping --no-gathering
```

#### **5. Display Facts in JSON Format**
```bash
ansible localhost -m setup -a "filter=ansible_fqdn" -v
```

#### **6. Gather Facts for Multiple Hosts**
```bash
ansible all -m setup
```

#### **7. Store Gathered Facts in a File**
```bash
ansible localhost -m setup -a "filter=ansible_hostname" > facts.json
```

#### **8. Include Facts in a Playbook**
```yaml
---
- name: Gather facts for localhost
  hosts: localhost
  tasks:
    - name: Gather facts
      setup:
```

---

### **Playbook Examples**

#### **1. Gather All Facts**
```yaml
---
- name: Gather all facts
  hosts: localhost
  tasks:
    - name: Gather facts
      setup:
```

#### **2. Filter Facts for Distribution**
```yaml
---
- name: Gather distribution facts
  hosts: localhost
  tasks:
    - name: Gather distribution facts
      setup:
        filter: ansible_distribution
```

#### **3. Store Facts in a Variable**
```yaml
---
- name: Store facts in a variable
  hosts: localhost
  tasks:
    - name: Gather all facts
      setup:
    - name: Show hostname
      debug:
        msg: "{{ ansible_fqdn }}"
```

#### **4. Use Gathered Facts in Conditions**
```yaml
---
- name: Conditional facts usage
  hosts: localhost
  tasks:
    - name: Gather facts
      setup:
    - name: Check OS
      debug:
        msg: "The OS is {{ ansible_distribution }}"
      when: ansible_distribution == "Ubuntu"
```

#### **5. Use Facts for Dynamic Configuration**
```yaml
---
- name: Use facts for dynamic configuration
  hosts: localhost
  tasks:
    - name: Gather facts
      setup:
    - name: Configure package based on facts
      apt:
        name: "{{ ansible_distribution | lower }}-package"
        state: present
```

#### **6. Gather Facts and Filter for Memory Information**
```yaml
---
- name: Gather memory facts
  hosts: localhost
  tasks:
    - name: Gather facts
      setup:
        filter: ansible_memtotal_mb
```

#### **7. Gather and Log Facts**
```yaml
---
- name: Gather and log facts
  hosts: localhost
  tasks:
    - name: Gather facts
      setup:
    - name: Log hostname
      debug:
        msg: "{{ ansible_fqdn }}"
```

#### **8. Using Facts for Host Configuration**
```yaml
---
- name: Use facts for host configuration
  hosts: localhost
  tasks:
    - name: Gather facts
      setup:
    - name: Configure hostname
      hostname:
        name: "{{ ansible_hostname }}-config"
```