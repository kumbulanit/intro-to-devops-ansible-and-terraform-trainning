### **Ansible Ad-Hoc Commands Cheat Sheet**

Ansible ad-hoc commands are used to quickly perform tasks on remote machines without the need to write a playbook. These commands are ideal for simple, one-off tasks such as checking configurations, managing services, or running commands across multiple hosts. Below is a cheat sheet with some commonly used Ansible ad-hoc command examples:

---

### **General Syntax**

```bash
ansible <host-pattern> -m <module> -a "<arguments>" [options]
```

- **`<host-pattern>`**: Defines the target hosts or groups (e.g., `all`, `webservers`, `localhost`).
- **`-m <module>`**: Specifies the module to use (e.g., `ping`, `command`, `copy`).
- **`-a "<arguments>"`**: Specifies the arguments to pass to the module.
- **[options]**: Additional options like verbosity or inventory.

---

### **Common Ansible Ad-Hoc Commands**

#### 1. **Ping Test**
Check if the target host is reachable:

```bash
ansible all -m ping
```

- **`all`**: Target all hosts.
- **`ping`**: A simple module that returns a `pong` message if the host is reachable.

#### 2. **Run a Shell Command**
Execute a shell command on a target machine:

```bash
ansible all -m command -a "uptime"
```

- **`command`**: Runs a command on the remote host (e.g., `uptime`, `ls`, etc.).

#### 3. **Copy a File to a Remote Host**
Copy a file to the target machine:

```bash
ansible all -m copy -a "src=/path/to/local/file dest=/path/to/remote/file"
```

- **`copy`**: Copies files from the control machine to the target machine.
- **`src`**: The source file on the local machine.
- **`dest`**: The destination path on the remote machine.

#### 4. **Check Disk Space**
Check available disk space on remote hosts:

```bash
ansible all -m command -a "df -h"
```

- **`df -h`**: Displays disk space usage in a human-readable format.

#### 5. **Install a Package**
Install a package using the appropriate package manager (e.g., `apt` for Ubuntu, `yum` for CentOS):

```bash
ansible all -m apt -a "name=curl state=present"
```

- **`apt`**: Manages packages on Debian-based systems.
- **`name`**: The name of the package to install.
- **`state=present`**: Ensures that the package is installed.

For Red Hat-based systems:

```bash
ansible all -m yum -a "name=curl state=present"
```

#### 6. **Start a Service**
Start a service (e.g., Apache HTTP server):

```bash
ansible all -m service -a "name=apache2 state=started"
```

- **`service`**: Manages services on the target machine.
- **`name`**: The service name.
- **`state=started`**: Ensures the service is started.

#### 7. **Reboot a Host**
Reboot the target machine:

```bash
ansible all -m reboot
```

- **`reboot`**: Reboots the remote machine.

#### 8. **Gather Facts**
Collect information (facts) about the target machine:

```bash
ansible all -m setup
```

- **`setup`**: Gathers detailed system facts (e.g., OS version, CPU, memory).

#### 9. **Manage Users**
Create or modify a user on a remote host:

```bash
ansible all -m user -a "name=johndoe state=present"
```

- **`user`**: Manages user accounts.
- **`name`**: The name of the user.
- **`state=present`**: Ensures the user exists.

#### 10. **Manage Groups**
Create or modify a group:

```bash
ansible all -m group -a "name=admin state=present"
```

- **`group`**: Manages groups on remote machines.
- **`name`**: The name of the group.
- **`state=present`**: Ensures the group exists.

#### 11. **File Permissions**
Change file permissions:

```bash
ansible all -m file -a "path=/path/to/file mode=0755"
```

- **`file`**: Manages file properties.
- **`mode=0755`**: Sets the file permissions.

#### 12. **Run a Command as Another User**
Execute a command as a different user (using `become`):

```bash
ansible all -m command -a "whoami" --become --become-user=nobody
```

- **`--become`**: Enables privilege escalation (e.g., `sudo`).
- **`--become-user`**: Specifies the user to run the command as.

---

### **Advanced Options**

#### 13. **Limiting Target Hosts**
Run a command only on specific hosts:

```bash
ansible webservers -m command -a "uptime"
```

- **`webservers`**: Run the command only on hosts in the `webservers` group.

#### 14. **Using Inventory File**
Specify a custom inventory file:

```bash
ansible all -m ping -i /path/to/inventory
```

- **`-i`**: Specifies the path to the inventory file.

#### 15. **Run with Increased Verbosity**
Increase the verbosity to debug the command execution:

```bash
ansible all -m ping -vv
```

- **`-vv`**: Increased verbosity level (more detailed output).

#### 16. **Dry Run (Check Mode)**
Check what changes would be made without applying them:

```bash
ansible all -m apt -a "name=curl state=present" --check
```

- **`--check`**: Run the task in "dry run" mode, showing what changes would be made without actually applying them.

#### 17. **Run in the Background**
Run a task in the background:

```bash
ansible all -m command -a "sleep 10" & 
```

- **`&`**: Executes the command in the background.

---

### **Common Modules**

- **ping**: Check if the host is reachable.
- **command**: Run a simple shell command.
- **copy**: Copy files to remote hosts.
- **apt**: Manage packages on Debian-based systems.
- **yum**: Manage packages on Red Hat-based systems.
- **service**: Start/stop services.
- **user**: Manage user accounts.
- **group**: Manage groups.
- **file**: Manage file properties.
- **setup**: Gather system facts.

---

