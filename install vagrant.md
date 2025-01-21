Below is a step-by-step guide to using Ansible to automate the installation of Vagrant, the configuration of two Ubuntu servers using Vagrant, and the setup of Docker as the provider for Vagrant with SSH access.

---

### **1. Prerequisites**
Ensure the following are installed on your control machine (the machine running Ansible):
- Python 3 and `pip`
- Ansible

Install Ansible if it’s not already installed:
```bash
sudo apt update
sudo apt install -y ansible
```

---

### **2. Ansible Playbook Overview**
The playbook will:
1. Install Vagrant and Docker on the control machine.
2. Configure Docker as the virtualization provider for Vagrant.
3. Use a Vagrantfile to create two Ubuntu-based Docker containers.
4. Set up SSH access to the two servers for Ansible.

---

### **3. Ansible Playbook Content**
Create a directory for the playbook and related files:
```bash
mkdir ~/ansible-vagrant-setup
cd ~/ansible-vagrant-setup
```

#### Create the Playbook File
Create a file called `setup_vagrant_docker.yml`:
```bash
nano setup_vagrant_docker.yml
```

**Playbook Content:**
```yaml
---
- name: Set up Vagrant with Docker provider and two Ubuntu servers
  hosts: localhost
  become: yes
  tasks:
    # Install dependencies
    - name: Install required packages
      apt:
        name: 
          - vagrant
          - docker.io
          - sshpass
        state: present
        update_cache: yes

    - name: Add current user to Docker group
      user:
        name: "{{ ansible_user }}"
        groups: docker
        append: yes

    - name: Install Vagrant Docker Compose plugin
      command: vagrant plugin install vagrant-docker-compose
      args:
        creates: /home/{{ ansible_user }}/.vagrant.d/plugins.json

    # Create a directory for Vagrantfile
    - name: Create a Vagrant project directory
      file:
        path: ~/vagrant-docker-project
        state: directory

    - name: Create the Vagrantfile
      copy:
        dest: ~/vagrant-docker-project/Vagrantfile
        content: |
          Vagrant.configure("2") do |config|
            config.vm.provider "docker" do |d|
              d.has_ssh = true
            end

            # Define the first Docker container
            config.vm.define "ubuntu-server-1" do |node1|
              node1.vm.provider "docker" do |d|
                d.image = "ubuntu:20.04"
                d.name = "ubuntu-server-1"
                d.remains_running = true
                d.ports = ["2222:22"]
              end
              node1.vm.hostname = "ubuntu-server-1"
              node1.ssh.username = "root"
            end

            # Define the second Docker container
            config.vm.define "ubuntu-server-2" do |node2|
              node2.vm.provider "docker" do |d|
                d.image = "ubuntu:20.04"
                d.name = "ubuntu-server-2"
                d.remains_running = true
                d.ports = ["2223:22"]
              end
              node2.vm.hostname = "ubuntu-server-2"
              node2.ssh.username = "root"
            end
          end

    # Bring up the Vagrant containers
    - name: Start the Vagrant containers
      command: vagrant up
      args:
        chdir: ~/vagrant-docker-project

    # Install SSH on containers
    - name: Install SSH on ubuntu-server-1
      command: >
        docker exec ubuntu-server-1 /bin/bash -c
        "apt-get update && apt-get install -y openssh-server && service ssh start"

    - name: Install SSH on ubuntu-server-2
      command: >
        docker exec ubuntu-server-2 /bin/bash -c
        "apt-get update && apt-get install -y openssh-server && service ssh start"
```

---

### **4. Run the Playbook**
1. Execute the playbook:
   ```bash
   ansible-playbook setup_vagrant_docker.yml
   ```

2. After running, verify that the containers are up and running:
   ```bash
   vagrant global-status
   ```

---

### **5. Configure Ansible Inventory for SSH Access**
1. Create an inventory file:
   ```bash
   nano inventory.yml
   ```

   **Content:**
   ```yaml
   all:
     hosts:
       ubuntu-server-1:
         ansible_host: 127.0.0.1
         ansible_port: 2222
         ansible_user: root
       ubuntu-server-2:
         ansible_host: 127.0.0.1
         ansible_port: 2223
         ansible_user: root
   ```

2. Test the connection:
   ```bash
   ansible all -i inventory.yml -m ping
   ```

---

### **Summary**
This playbook automates:
1. Installing Vagrant and Docker.
2. Configuring Docker as the provider for Vagrant.
3. Creating two Ubuntu servers running in Docker containers.
4. Setting up SSH for Ansible to communicate with the servers.

