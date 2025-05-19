
# 🧪 Modular Ansible Lab Series: Topics by Playbook + Final Integration
# Estimated Duration: 60–75 minutes
# Objective: Learn each concept individually, then combine them into one cohesive playbook

# =====================================
# 🧰 LAB STRUCTURE
# =====================================
# Each topic will have its own playbook file to demonstrate core functionality. The final playbook will integrate all topics.
```
# Folders:
# ~/ansible-lab-modular/
# ├── inventory.ini
# ├── vars/
# │   └── userlist.yml
# ├── templates/
# │   └── userinfo.j2
# ├── playbooks/
# │   ├── 1_variables_loops.yml
# │   ├── 2_complex_loops.yml
# │   ├── 3_variables_templates.yml
# │   ├── 4_variables_conditions.yml
# │   ├── 5_blocks.yml
# │   ├── 6_prompts.yml
# │   ├── 7_system_facts.yml
# │   ├── 8_set_variables.yml
# │   ├── 9_registered_variables.yml
# │   ├── 10_cli_variables.yml
# │   └── final_combined_lab.yml
```

# =====================================
### 🧾 INVENTORY FILE
```bash
cat > ~/ansible-lab-modular/inventory.ini <<EOF
[local]
localhost ansible_connection=local
EOF
```

# =====================================
### 🔁 1. Variables and Loops
```bash
cat > ~/ansible-lab-modular/playbooks/1_variables_loops.yml <<EOF
- name: Basic Variables and Loops
hosts: all
vars:
user: ansible_student
loop_count: 3
tasks:
- name: Loop through a range
debug:
msg: "Hello {{ user }} - loop {{ item }}"
loop: "{{ range(1, loop_count + 1) | list }}"
EOF
```
# =====================================
### 📚 2. Complex Variables in Loops
```bash
cat > ~/ansible-lab-modular/vars/userlist.yml <<EOF
users:
- name: alice
shell: /bin/bash
group: sudo
- name: bob
shell: /bin/zsh
group: developers
EOF

```bash
cat > ~/ansible-lab-modular/playbooks/2_complex_loops.yml <<EOF
- name: Complex Variables in Loops
hosts: all
vars_files:
- ../vars/userlist.yml
tasks:
- name: Create users from list
user:
name: "{{ item.name }}"
shell: "{{ item.shell }}"
groups: "{{ item.group }}"
state: present
loop: "{{ users }}"
EOF
```

# =====================================
### 📝 3. Variables and Templates
```bash
cat > ~/ansible-lab-modular/templates/userinfo.j2 <<EOF
Welcome {{ user }}
Host: {{ ansible_facts['hostname'] }}
Time: {{ current_time }}
EOF
```
```bash
cat > ~/ansible-lab-modular/playbooks/3_variables_templates.yml <<EOF
- name: Variables and Templates
hosts: all
vars:
user: template_user
current_time: "2025-07-01 10:00"
tasks:
- name: Generate template
template:
src: ../templates/userinfo.j2
dest: "/tmp/userinfo_{{ user }}.txt"
EOF
```

# =====================================
### ❗ 4. Using Variables in Conditions
```bash
cat > ~/ansible-lab-modular/playbooks/4_variables_conditions.yml <<EOF
- name: Conditionals with Variables
hosts: all
vars:
run_task: true
tasks:
- name: Only run this when run_task is true
debug:
msg: "Task executed because run_task is {{ run_task }}"
when: run_task
EOF
```

# =====================================
### 🔳 5. Blocks
```bash
cat > ~/ansible-lab-modular/playbooks/5_blocks.yml <<EOF
- name: Block with rescue and always
hosts: all
tasks:
- block:
- name: Try failing task
command: /bin/false
rescue:
- debug:
msg: "Rescued from error"
always:
- debug:
msg: "Always runs"
EOF
```
# =====================================
### 🙋 6. Prompts
```bash
cat > ~/ansible-lab-modular/playbooks/6_prompts.yml <<EOF
- name: Prompt Example
hosts: all
vars_prompt:
- name: username
prompt: "Enter your name"
tasks:
- debug:
msg: "Hello {{ username }}!"
EOF
```

# =====================================
### 🧠 7. System Facts
```bash
cat > ~/ansible-lab-modular/playbooks/7_system_facts.yml <<EOF
- name: Use System Facts
hosts: all
gather_facts: true
tasks:
- debug:
msg: "OS: {{ ansible_facts['distribution'] }}"
EOF
```

# =====================================
### ✍️ 8. Set Variables in Playbook
```bash
cat > ~/ansible-lab-modular/playbooks/8_set_variables.yml <<EOF
- name: set_fact usage
hosts: all
tasks:
- set_fact:
custom_message: "Set at runtime"
- debug:
var: custom_message
EOF
```

# =====================================
### 🧾 9. Registered Variables
```bash
cat > ~/ansible-lab-modular/playbooks/9_registered_variables.yml <<EOF
- name: Register and reuse command output
hosts: all
tasks:
- shell: echo "dynamic value"
register: result
- debug:
var: result.stdout
EOF
```

# =====================================
### 🔄 10. CLI Variables
```bash
cat > ~/ansible-lab-modular/playbooks/10_cli_variables.yml <<EOF
- name: CLI Variables Demo
hosts: all
tasks:
- debug:
msg: "Run mode: {{ mode | default('not set') }}"
EOF
```

# =====================================
### 🧩 FINAL LAB: Combine Everything
```bash
cat > ~/ansible-lab-modular/playbooks/final_combined_lab.yml <<EOF
- name: Final Integrated Lab
hosts: all
gather_facts: true
vars_prompt:
- name: user
prompt: "Enter your name"
vars:
env: dev
vars_files:
- ../vars/userlist.yml
tasks:
- name: Display facts and prompt
debug:
msg: "Hi {{ user }}, running on {{ ansible_facts['distribution'] }}"

- name: Loop over list of users
debug:
msg: "User: {{ item.name }} | Shell: {{ item.shell }}"
loop: "{{ users }}"

- name: Register and use output
shell: date
register: date_output

- set_fact:
current_time: "{{ date_output.stdout }}"

- template:
src: ../templates/userinfo.j2
dest: "/tmp/final_userinfo_{{ user }}.txt"

- block:
- name: Trigger error
command: /bin/false
rescue:
- debug:
msg: "Error handled"
always:
- debug:
msg: "Finished block section"

- debug:
msg: "Command line mode: {{ mode | default('none') }}"
EOF
``` 

# =====================================
# ✅ INSTRUCTIONS
# =====================================
# Run each playbook one at a time:
# cd ~/ansible-lab-modular/playbooks
# ansible-playbook -i ../inventory.ini 1_variables_loops.yml
# ...
# ansible-playbook -i ../inventory.ini final_combined_lab.yml --extra-vars "mode=final"

