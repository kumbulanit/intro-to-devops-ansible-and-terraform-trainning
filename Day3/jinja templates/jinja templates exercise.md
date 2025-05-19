---
# 🧪 Full Ansible Hands-On Lab: Foundational to Advanced Concepts
# This lab includes Ansible + OpenStack automation, and now a full walkthrough of Jinja2 template usage.

# =====================================
# 📦 JINJA2 HANDS-ON LAB: SIMPLE TO ADVANCED
# Duration: 60–75 minutes
# =====================================

```
# 📁 Directory Structure:
# jinja2-lab/
# ├── inventory.ini
# ├── jinja2-playbook.yml
# ├── group_vars/
# │   └── all.yml
# ├── host_vars/
# │   └── localhost.yml
# ├── templates/
# │   ├── welcome.j2
# │   ├── config_filter_demo.j2
# │   ├── logic_test_demo.j2
# │   └── feature_list.j2
# └── facts_tasks.yml
```

# =====================================
# 🧰 LAB SETUP INSTRUCTIONS (STEP BY STEP)
# =====================================

# Step 1: Create the working lab environment
```bash
mkdir -p ~/jinja2-lab/{group_vars,host_vars,templates}
cd ~/jinja2-lab
```
# Step 2: Create the static inventory
```bash
cat > inventory.ini <<EOF
[local]
localhost ansible_connection=local
EOF
```
# Step 3: Create group_vars for shared values

```bash
cat > group_vars/all.yml <<EOF
user_name: Alice
company: DevCorp
env: production
website: devcorp.com
features:
- backup
- monitoring
- analytics
EOF
```

# Step 4: Create host_vars for localhost-specific values
```bash
cat > host_vars/localhost.yml <<EOF
config:
port: 443
enabled: true
retries: 3
alert_email: alerts@devcorp.com
EOF
```

# Step 5: Create basic welcome.j2 template
```bash
cat > templates/welcome.j2 <<EOF
Welcome {{ user_name }} to {{ company }}!
You are visiting the {{ env }} environment.
Visit us at: {{ website }}
EOF
```

# Step 6: Create a template to demonstrate filters
```bash
cat > templates/config_filter_demo.j2 <<EOF
Config Report for {{ company | upper }}
====================================
Service Enabled: {{ config.enabled | string | upper }}
Listening Port: {{ config.port | int }}
Retries Allowed: {{ config.retries | int }}
Alert Contact: {{ config.alert_email | replace("@", " [at] ") }}

Enabled Features:
{% for feature in features %}
- {{ feature | capitalize }}
{% endfor %}
EOF
```

# Step 7: Create a template to demonstrate tests and logic
```bash
cat > templates/logic_test_demo.j2 <<EOF
{% if config.enabled is defined and config.enabled %}
[INFO] Service is enabled.
{% else %}
[WARNING] Service is not enabled.
{% endif %}

{% if env is string %}
Environment is valid: {{ env }}
{% endif %}

{% if features is iterable %}
Feature Count: {{ features | length }}
{% endif %}
EOF
```

# Step 8: Create another template to loop and use filters/tests together
```bash
cat > templates/feature_list.j2 <<EOF
{% for feature in features if feature is string %}
Feature: {{ feature | upper }} | Length: {{ feature | length }}
{% else %}
No valid features found.
{% endfor %}
EOF
```

# Step 9: Create a fact-setting task file
```bash
cat > facts_tasks.yml <<EOF
- name: Set dynamic facts
set_fact:
status_message: "Configuration loaded successfully"
instance_count: 3
EOF
```
# Step 10: Create the main playbook
```bash
cat > jinja2-playbook.yml <<EOF
- name: Jinja2 Training Lab
hosts: all
gather_facts: false

vars_prompt:
- name: input_env
prompt: "Enter environment name (dev, test, prod)"
private: no

pre_tasks:
- name: Override environment with prompt
set_fact:
env: "{{ input_env }}"

- name: Load extra facts
include_tasks: facts_tasks.yml

tasks:
- name: Render welcome template
template:
src: templates/welcome.j2
dest: /tmp/welcome.html

- name: Render filter demo template
template:
src: templates/config_filter_demo.j2
dest: /tmp/filtered_config.txt

- name: Render logic test demo template
template:
src: templates/logic_test_demo.j2
dest: /tmp/logic_output.txt

- name: Render advanced feature list
template:
src: templates/feature_list.j2
dest: /tmp/features_output.txt

- name: Show final status
debug:
msg: "{{ status_message }} - {{ instance_count }} instance(s) planned"
EOF
```

# Step 11: Run the playbook
```bash
ansible-playbook -i inventory.ini jinja2-playbook.yml
```
# Step 12: Verify the output files
```bash
cat /tmp/welcome.html
cat /tmp/filtered_config.txt
cat /tmp/logic_output.txt
cat /tmp/features_output.txt
```

# =====================================
# 📚 OFFICIAL DOCUMENTATION FOR REFERENCE
# =====================================
# Ansible Templates: https://docs.ansible.com/ansible/latest/user_guide/playbooks_templating.html
# Jinja2 Docs: https://jinja.palletsprojects.com/en/latest/templates/


# =====================================
# 🧠 BONUS CHALLENGES (for individual or group work)
# =====================================
# 1. Add a new feature to config and use `selectattr` to filter enabled features only
# 2. Create a template that generates a `systemd` service file from variables
# 3. Use a loop with conditions (e.g., only list features longer than 5 chars)
# 4. Add debug output showing if certain variables were undefined and handled properly
# 5. Create templates per environment and switch between them using `when` conditions
