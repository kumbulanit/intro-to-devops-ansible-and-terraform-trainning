---
# 🧪 Ansible Hands-On Lab: Mastering Variables from Simple to Advanced
# Duration: 30–45 minutes
# Concepts Covered:
# • Prompts
# • Getting variables from the system (facts)
# • Setting variables in playbooks
# • Registered variables
# • Getting variables from the command line
# • Where to derive variable values (precedence)

# =====================================
# 🧰 LAB SETUP INSTRUCTIONS
# =====================================

# Step 1: Create your lab working directory
```bash
mkdir -p ~/ansible-vars-lab/{templates,vars}
cd ~/ansible-vars-lab
```
# Step 2: Create your inventory file
```bash
cat > inventory.ini <<EOF
[local]
localhost ansible_connection=local
EOF
```
# Step 3: Create template to test multiple variables
```bash
cat > templates/greeting.j2 <<EOF
Hello {{ username }}!
Your hostname is: {{ ansible_facts['hostname'] }}
You are running: {{ ansible_facts['distribution'] }} {{ ansible_facts['distribution_version'] }}
Current time: {{ current_time }}
Debug mode: {{ debug_mode | default(false) }}
EOF
```
# =====================================
# 📄 PLAYBOOK: vars-lab.yml
# =====================================
```bash
cat > vars-lab.yml <<EOF
- name: Ansible Variables Lab (Simple to Advanced)
hosts: all
gather_facts: true

vars_prompt:
- name: username
prompt: "Please enter your name"
private: no

vars:
greeting_enabled: true
message: "This is a static message defined in vars block"
fallback_app: "curl"

tasks:
### 1. SYSTEM VARIABLES (FACTS) ###
- name: Display system distribution and version
debug:
msg: "Running on {{ ansible_facts['distribution'] }} {{ ansible_facts['distribution_version'] }}"

- name: Display system hostname and IP
debug:
msg: "Hostname: {{ ansible_facts['hostname'] }}, IP: {{ ansible_facts['default_ipv4']['address'] }}"

### 2. PROMPT VARIABLE ###
- name: Show user name entered via prompt
debug:
msg: "Hello, {{ username }}!"

### 3. STATIC PLAYBOOK VARIABLE ###
- name: Show static variable defined in vars
debug:
var: message

### 4. REGISTERED VARIABLES ###
- name: Capture current system time using shell command
shell: date
register: time_output

- name: Set dynamic variable from registered value
set_fact:
current_time: "{{ time_output.stdout }}"

- name: Print registered and fact-based variable
debug:
msg: "The current system time is: {{ current_time }}"

### 5. CONDITIONAL TASK USING SYSTEM FACT ###
- name: Conditionally run task based on system fact (Debian only)
debug:
msg: "This task runs only on Debian-based systems"
when: ansible_facts['os_family'] == 'Debian'

### 6. CONDITIONAL TASK USING COMMAND-LINE VARIABLE ###
- name: Conditional message if debug_mode is passed via CLI
debug:
msg: "Debug mode is enabled!"
when: debug_mode | default(false)

### 7. TEMPLATE TASK: INTEGRATE MULTIPLE VARIABLES ###
- name: Render greeting template with all types of variables
template:
src: templates/greeting.j2
dest: "/tmp/greeting_{{ username }}.txt"

### 8. BLOCK + VARIABLE CONTROL ###
- name: Try installing a non-existent package with rescue block
block:
- name: Simulate failure with nonexistent package
apt:
name: nonexistent-package
state: present
become: yes

rescue:
- name: Handle failure and install fallback package
apt:
name: "{{ fallback_app }}"
state: present
become: yes

always:
- name: Cleanup message
debug:
msg: "Block completed (success or fail)"
EOF
```
# =====================================
# ▶️ HOW TO EXECUTE LAB
# =====================================
# Step 1: Enter the directory
```bash
cd ~/ansible-vars-lab
```
####Step 2: Run without extra-vars (observe default behavior)
```bash
ansible-playbook -i inventory.ini vars-lab.yml
```
# Step 3: Run with a command-line override for debug mode
```bash
ansible-playbook -i inventory.ini vars-lab.yml --extra-vars "debug_mode=true"
```
# Step 4: View template output
```bash
cat /tmp/greeting_<your_username>.txt
```
# =====================================
# 🧠 LAB OBJECTIVES & WHAT TO LEARN
# =====================================
# ✅ Prompt users for input and use their responses
# ✅ Retrieve system information with facts
# ✅ Define and use static variables from playbooks
# ✅ Use registered variables and manipulate output
# ✅ Dynamically inject values from command line with `--extra-vars`
# ✅ Apply `when:` conditions using any variable type
# ✅ Create a template that brings all variable sources together
# ✅ Use blocks and fallback logic for error handling


