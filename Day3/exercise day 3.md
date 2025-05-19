---
# 🧪 Comprehensive Ansible Lab (1.5 Hours)
# Topics Covered:
# ✅ Ansible Config and Structure
# ✅ Host Inventory and Variable Files
# ✅ Roles and Best Practices
# ✅ Key Server Modules (setup, apt/yum, copy, shell, git, etc.)
# ✅ Jinja2 (Variables, Filters, Tests, Templates)
# ✅ Conditionals and Looping Tasks
# ✅ Prompting, Registering, CLI Variables

# 📁 Directory Tree:
# ansible-lab/
# ├── ansible.cfg
# ├── inventory.ini
# ├── group_vars/
# │   └── all.yml
# ├── host_vars/
# │   └── localhost.yml
# ├── roles/
# │   └── webapp/ (with standard role subfolders)
# ├── templates/
# │   └── welcome.j2
# ├── files/
# │   └── static.conf
# ├── vars/
# │   └── users.yml
# └── playbooks/
#     ├── 1_config_inventory.yml
#     ├── 2_roles_structure.yml
#     ├── 3_server_modules.yml
#     ├── 4_jinja_templates.yml
#     ├── 5_conditionals_loops.yml
#     └── 6_final_integration.yml

# =====================================
# ✅ CONFIG FILE: ansible.cfg
cat > ~/ansible-lab/ansible.cfg <<EOF
[defaults]
inventory = inventory.ini
roles_path = ./roles
retry_files_enabled = false
host_key_checking = false
defaults_file = ./ansible.cfg
EOF

# ✅ INVENTORY FILE
cat > ~/ansible-lab/inventory.ini <<EOF
[local]
localhost ansible_connection=local
EOF

# ✅ GROUP VARS
mkdir -p ~/ansible-lab/group_vars
cat > ~/ansible-lab/group_vars/all.yml <<EOF
app_name: ansible_demo
admin_email: admin@example.com
EOF

# ✅ HOST VARS
mkdir -p ~/ansible-lab/host_vars
cat > ~/ansible-lab/host_vars/localhost.yml <<EOF
deployment_env: dev
EOF

# ✅ USERS VARS FILE
mkdir -p ~/ansible-lab/vars
cat > ~/ansible-lab/vars/users.yml <<EOF
users:
- name: alice
group: admin
- name: bob
group: devops
EOF

# ✅ TEMPLATE
mkdir -p ~/ansible-lab/templates
cat > ~/ansible-lab/templates/welcome.j2 <<EOF
Welcome {{ user }}!
This is the {{ app_name }} running on {{ ansible_facts['hostname'] }}.
Deployment environment: {{ deployment_env }}
EOF

# ✅ FILE TO COPY
mkdir -p ~/ansible-lab/files
cat > ~/ansible-lab/files/static.conf <<EOF
# Static config file
log_level=INFO
auth_enabled=true
EOF

# ✅ ROLE STRUCTURE (webapp role)
mkdir -p ~/ansible-lab/roles/webapp/{tasks,handlers,templates,defaults,vars}
cat > ~/ansible-lab/roles/webapp/tasks/main.yml <<EOF
- name: Ensure Nginx is installed
apt:
name: nginx
state: present
update_cache: yes

- name: Copy static configuration
copy:
src: ../../files/static.conf
dest: /etc/nginx/conf.d/static.conf
notify: Restart nginx
EOF

cat > ~/ansible-lab/roles/webapp/handlers/main.yml <<EOF
- name: Restart nginx
service:
name: nginx
state: restarted
EOF

cat > ~/ansible-lab/roles/webapp/templates/welcome.j2 <<EOF
<html><body>
<h1>Welcome to {{ app_name }}</h1>
<p>Host: {{ ansible_hostname }}</p>
<p>Environment: {{ deployment_env }}</p>
</body></html>
EOF

cat > ~/ansible-lab/roles/webapp/defaults/main.yml <<EOF
web_port: 80
EOF

# =====================================
# ✅ PLAYBOOKS PER TOPIC
mkdir -p ~/ansible-lab/playbooks

## 1. Config and Inventory
cat > ~/ansible-lab/playbooks/1_config_inventory.yml <<EOF
- name: Verify config and inventory
hosts: all
tasks:
- debug:
msg: "Running on {{ inventory_hostname }} using config from ansible.cfg"
EOF

## 2. Roles and Structure
cat > ~/ansible-lab/playbooks/2_roles_structure.yml <<EOF
- name: Use webapp role
hosts: all
roles:
- webapp
EOF

## 3. Server Modules
cat > ~/ansible-lab/playbooks/3_server_modules.yml <<EOF
- name: Explore common modules
hosts: all
tasks:
- name: Gather facts
setup:

- name: Install packages
apt:
name: [curl, git]
state: present

- name: Clone Git repo
git:
repo: https://github.com/ansible/ansible-examples.git
dest: /tmp/ansible-examples

- name: Use lineinfile
lineinfile:
path: /tmp/demo.conf
line: 'enable_feature=true'
create: yes

- name: Download file
get_url:
url: https://httpbin.org/get
dest: /tmp/httpbin-response.json

- name: Run shell command
shell: uptime
register: uptime_output

- debug:
var: uptime_output.stdout
EOF

## 4. Jinja Templates
cat > ~/ansible-lab/playbooks/4_jinja_templates.yml <<EOF
- name: Jinja template exercise
hosts: all
vars:
user: jinja_demo_user
deployment_env: stage
tasks:
- name: Render welcome template
template:
src: ../templates/welcome.j2
dest: /tmp/welcome_jinja.txt
EOF

## 5. Conditional and Looping Tasks
cat > ~/ansible-lab/playbooks/5_conditionals_loops.yml <<EOF
- name: Conditional and Loops
hosts: all
vars_files:
- ../vars/users.yml
vars:
allow_loop: true
tasks:
- name: Loop over users
user:
name: "{{ item.name }}"
groups: "{{ item.group }}"
state: present
loop: "{{ users }}"
when: allow_loop

- name: Prompt example
pause:
prompt: "Do you want to continue?"

- name: Register example
shell: date
register: date_out

- debug:
msg: "Current time is {{ date_out.stdout }}"
EOF

# =====================================
# ✅ FINAL INTEGRATION PLAYBOOK
cat > ~/ansible-lab/playbooks/6_final_integration.yml <<EOF
- name: Full Integration of Concepts
hosts: all
gather_facts: true
vars_prompt:
- name: cli_user
prompt: "Enter the deployment user"
vars:
app_name: production_app
vars_files:
- ../vars/users.yml
roles:
- webapp
tasks:
- debug:
msg: "Welcome {{ cli_user }} to {{ app_name }} deployment!"

- name: Create looped users
user:
name: "{{ item.name }}"
groups: "{{ item.group }}"
state: present
loop: "{{ users }}"

- name: Run only in dev environment
debug:
msg: "Dev environment task running"
when: deployment_env == 'dev'

- name: Run command and register
shell: whoami
register: user_output

- debug:
var: user_output.stdout

- name: Use Jinja template
template:
src: ../templates/welcome.j2
dest: "/tmp/final_welcome_{{ cli_user }}.txt"
EOF

# =====================================
# ✅ EXECUTION INSTRUCTIONS
# cd ~/ansible-lab/playbooks
# ansible-playbook -i ../inventory.ini 1_config_inventory.yml
# ansible-playbook -i ../inventory.ini 2_roles_structure.yml
# ansible-playbook -i ../inventory.ini 3_server_modules.yml
# ansible-playbook -i ../inventory.ini 4_jinja_templates.yml
# ansible-playbook -i ../inventory.ini 5_conditionals_loops.yml
# ansible-playbook -i ../inventory.ini 6_final_integration.yml

