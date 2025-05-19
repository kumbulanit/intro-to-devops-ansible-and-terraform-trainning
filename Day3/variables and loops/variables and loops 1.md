
# 🧪 Hands-On Ansible Lab: Variables, Loops, Templates, Conditions, and Blocks
# Duration: 30–45 minutes
# Concepts Covered:
# • Variables and Loops
# • Using Complex Variables in Loops
# • Variables and Templates
# • Using Variables in Conditions
# • Blocks

# =====================================
# 🧰 LAB SETUP INSTRUCTIONS
# =====================================

### Step 1: Create your lab directory
```bash
mkdir -p ~/ansible-lab/{templates,vars}
cd ~/ansible-lab
```
### Step 2: Create inventory file
```bash
cat > inventory.ini <<EOF
[local]
localhost ansible_connection=local
EOF
```
### Step 3: Create variable file for external loading
```bash
cat > vars/userlist.yml <<EOF
users:
- name: alice
shell: /bin/bash
groups: sudo
- name: bob
shell: /bin/zsh
groups: developers
EOF
```

### Step 4: Create a basic template file
```bash
cat > templates/welcome.j2 <<EOF
Welcome {{ user }}!
You're accessing this system with hostname {{ ansible_facts['hostname'] }}.
EOF
```

# =====================================
# 📄 PLAYBOOK: ansible-lab.yml
# =====================================
```bash
cat > ansible-lab.yml <<EOF
- name: Ansible Core Lab
hosts: all
gather_facts: true

vars:
app_env: production
welcome_user: trainer
message_repeat: 3

vars_files:
- vars/userlist.yml

tasks:

### Part 1: Simple Variable and Loop ###
- name: Repeat welcome message using loop
debug:
msg: "Hello {{ welcome_user }} - iteration {{ item }}"
loop: "{{ range(1, message_repeat + 1) | list }}"

### Part 2: Complex Variables and Loops ###
- name: Create users with custom attributes
user:
name: "{{ item.name }}"
shell: "{{ item.shell }}"
groups: "{{ item.groups }}"
state: present
loop: "{{ users }}"

### Part 3: Using Template with Variables ###
- name: Create welcome message using template
template:
src: templates/welcome.j2
dest: "/tmp/welcome_{{ welcome_user }}.txt"

### Part 4: Using Variables in Conditions ###
- name: Run only in production
debug:
msg: "Environment is production, starting app setup."
when: app_env == "production"

- name: Run only for bash users
debug:
msg: "User {{ item.name }} uses bash."
when: item.shell == "/bin/bash"
loop: "{{ users }}"

### Part 5: Blocks and Rescue ###
- name: Demonstrate blocks with fallback
block:
- name: Try to install a non-existent package
apt:
name: nonexist-pkg
state: present
rescue:
- name: Handle failure
debug:
msg: "Fallback: The package failed. Installing curl instead."
- name: Install curl
apt:
name: curl
state: present
always:
- name: Always run after block
debug:
msg: "Cleanup or final step regardless of failure"
EOF
```

# =====================================
# ▶️ HOW TO RUN
# =====================================
### Step 1: Ensure you are in the lab directory
```bash
cd ~/ansible-lab
```

### Step 2: Run the playbook
```bash
ansible-playbook -i inventory.ini ansible-lab.yml
```

### Step 3: View output files
```bash
cat /tmp/welcome_trainer.txt
```

# =====================================
# 📚 LAB SUMMARY
# =====================================
# ✅ Part 1: Basic loop over a range using variables
# ✅ Part 2: Loop over complex dictionaries (user creation)
# ✅ Part 3: Use variables inside a Jinja2 template
# ✅ Part 4: Conditional task execution using variables
# ✅ Part 5: Group tasks inside blocks with error handling (rescue) and guaranteed cleanup (always)


