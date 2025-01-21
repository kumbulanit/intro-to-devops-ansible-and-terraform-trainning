# Comprehensive Guide to Ansible Ad-Hoc Commands

---

## **Ad-Hoc Commands**

### **Simple Commands**

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

### **Intermediate Commands**

5. **Create a file:**
   ```bash
   ansible all -i ~/inventory -m file -a "path=/tmp/ansible_test_file state=touch"
   ```

6. **Install a package (e.g., `curl`):**
   ```bash
   ansible all -i ~/inventory -m apt -a "name=curl state=present update_cache=yes"
   ```

7. **Remove a package:**
   ```bash
   ansible all -i ~/inventory -m apt -a "name=curl state=absent"
   ```

8. **Restart a service (e.g., `ssh`):**
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

### **Advanced Commands**

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

### **Very Advanced Commands**

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

## **Testing and Practice**

- Use these commands to practice Ansible operations on your localhost.
- Gradually move from basic commands to advanced ones.
- Combine commands to create complex automation scenarios.

---

## **Cleanup**

After testing, clean up the generated files and directories:
```bash
ansible all -i ~/inventory -a "rm -rf /tmp/ansible_test_file /tmp/ansible_test_dir /tmp/hosts_copy /tmp/hello.txt"
```


