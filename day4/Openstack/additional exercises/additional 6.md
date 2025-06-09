# 🎓 Hands-On Lab: OpenStack Automation with Ansible SDK and Modules

(...existing content...)

---

## 🍽️ Follow-up Exercise: Install and Verify NGINX Web Server on Frontend VM

This task extends the previous multi-tier application lab. After launching the `frontend-vm`, you’ll install NGINX and verify the web server is reachable over HTTP.

### ✅ Exercise 5: Install NGINX on Frontend VM and Verify

```yaml
# ex5_install_nginx_frontend.yml
- name: Install NGINX on frontend VM
  hosts: frontend
  become: yes
  vars:
    ansible_user: ubuntu
  tasks:
    - name: Update APT repo
      apt:
        update_cache: yes

    - name: Install NGINX
      apt:
        name: nginx
        state: present

    - name: Ensure NGINX is running
      service:
        name: nginx
        state: started
        enabled: true

    - name: Add custom index page
      copy:
        dest: /var/www/html/index.html
        content: "<h1>This is the Frontend Role VM with NGINX</h1>"
```

---

### 🧩 How to Run

1. Ensure your `inventory.ini` includes the frontend VM's floating IP:

```ini
[frontend]
<frontend_vm_floating_ip> ansible_ssh_private_key_file=~/.ssh/id_rsa ansible_user=ubuntu
```

2. Run the playbook:

```bash
ansible-playbook -i inventory.ini ex5_install_nginx_frontend.yml
```

3. Verify via browser or `curl`:

```bash
curl http://<frontend_vm_floating_ip>
```

---

✅ You’ve now deployed and verified a working web server on an OpenStack-hosted VM using Ansible. This concludes the full automation cycle from provision to application deployment!
