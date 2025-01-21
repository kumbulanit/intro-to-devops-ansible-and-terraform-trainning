Using **Docker** as the provider for Vagrant is a lightweight alternative to VirtualBox. Below is the step-by-step guide to creating two Ubuntu-based Docker containers using Vagrant and configuring them for Ansible practice.

---

### **1. Prerequisites**
1. **Install Docker**:
   ```bash
   sudo apt update
   sudo apt install -y docker.io
   sudo systemctl start docker
   sudo systemctl enable docker
   ```
   Add your user to the Docker group to avoid using `sudo`:
   ```bash
   sudo usermod -aG docker $USER
   ```
   Log out and back in for the changes to take effect.

2. **Install Vagrant**:
   ```bash
   sudo apt install -y vagrant
   ```

3. **Install Vagrant Docker Plugin** (optional, ensures Docker works seamlessly with Vagrant):
   ```bash
   vagrant plugin install vagrant-docker-compose
   ```

---

### **2. Create a Vagrant Configuration**

1. Create a project directory:
   ```bash
   mkdir -p ~/vagrant-docker-ansible
   cd ~/vagrant-docker-ansible
   ```

2. Initialize a new Vagrantfile:
   ```bash
   vagrant init
   ```

3. Edit the **Vagrantfile**:
   ```bash
   nano Vagrantfile
   ```

   **Content:**
   ```ruby
   Vagrant.configure("2") do |config|
     config.vm.provider "docker" do |d|
       d.has_ssh = true
     end

     # Define the first Docker container
     config.vm.define "ansible-node1" do |node1|
       node1.vm.provider "docker" do |d|
         d.image = "ubuntu:20.04"
         d.name = "ansible-node1"
         d.remains_running = true
         d.ports = ["2222:22"]
       end
       node1.vm.hostname = "ansible-node1"
       node1.ssh.username = "root"
     end

     # Define the second Docker container
     config.vm.define "ansible-node2" do |node2|
       node2.vm.provider "docker" do |d|
         d.image = "ubuntu:20.04"
         d.name = "ansible-node2"
         d.remains_running = true
         d.ports = ["2223:22"]
       end
       node2.vm.hostname = "ansible-node2"
       node2.ssh.username = "root"
     end
   end
   ```

4. Start the Vagrant containers:
   ```bash
   vagrant up
   ```

5. Verify the status:
   ```bash
   vagrant status
   ```

---

### **3. Install SSH Server in the Containers**

By default, Ubuntu Docker images do not have an SSH server installed. We'll install it using Vagrant's SSH access:

1. SSH into each container:
   ```bash
   vagrant ssh ansible-node1
   ```

2. Inside the container, install and configure SSH:
   ```bash
   apt update
   apt install -y openssh-server
   service ssh start
   ```
   Exit the container:
   ```bash
   exit
   ```

3. Repeat the steps for `ansible-node2`.

---

### **4. Configure Ansible Inventory**

1. Create an inventory file:
   ```bash
   mkdir -p ~/ansible-practice
   cd ~/ansible-practice
   nano inventory.yml
   ```

   **Content:**
   ```yaml
   all:
     hosts:
       ansible-node1:
         ansible_host: 127.0.0.1
         ansible_port: 2222
         ansible_user: root
       ansible-node2:
         ansible_host: 127.0.0.1
         ansible_port: 2223
         ansible_user: root
   ```

2. Test connectivity:
   ```bash
   ansible all -i inventory.yml -m ping
   ```

---

### **5. Write a Simple Playbook**

Create a playbook to install Apache on the containers:

1. Create a playbook:
   ```bash
   nano webserver.yml
   ```

   **Content:**
   ```yaml
   ---
   - name: Configure Web Servers
     hosts: all
     become: yes

     tasks:
       - name: Update apt cache
         apt:
           update_cache: yes

       - name: Install Apache
         apt:
           name: apache2
           state: present

       - name: Ensure Apache is running
         service:
           name: apache2
           state: started
           enabled: yes

       - name: Deploy a sample webpage
         copy:
           dest: /var/www/html/index.html
           content: |
             <html>
             <head><title>Ansible Web Server</title></head>
             <body>
               <h1>Welcome to {{ inventory_hostname }}</h1>
             </body>
             </html>
   ```

2. Run the playbook:
   ```bash
   ansible-playbook -i inventory.yml webserver.yml
   ```

---

### **6. Verify the Setup**

1. Access the web servers:
   - `http://127.0.0.1:2222`
   - `http://127.0.0.1:2223`

2. Both servers should display a custom webpage.

---

### **Summary**
This configuration:
- Uses Vagrant with Docker to create two Ubuntu containers.
- Installs SSH for Ansible communication.
- Configures a static inventory for Ansible.
- Deploys Apache web servers with Ansible.

https://computingforgeeks.com/install-latest-vagrant-on-ubuntu/