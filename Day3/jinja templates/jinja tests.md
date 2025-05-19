---
# 🧪 Full Ansible Hands-On Lab: Foundational to Advanced Concepts
# Tand now a dedicated test lab for Jinja2 tests.

# =====================================
# 🧪 JINJA2 TEST SCENARIOS: TEST LAB
# Duration: 20–30 minutes
# =====================================
```
# 📁 Directory Structure:
# jinja2-test-lab/
# ├── inventory.ini
# └── jinja2-tests-playbook.yml
```
# =====================================
# 🧰 SETUP INSTRUCTIONS
# =====================================

# Step 1: Create working directory
```bash
mkdir -p ~/jinja2-test-lab
cd ~/jinja2-test-lab
```

# Step 2: Create inventory file
```yaml
cat > inventory.ini <<EOF
[local]
localhost ansible_connection=local
EOF
```

# Step 3: Create the playbook file with test cases
```bash
cat > jinja2-tests-playbook.yml <<EOF
- name: Jinja2 Test Scenarios Lab
hosts: localhost
gather_facts: false

vars:
user_name: Alice
email: alice@example.com
age: 30
score: 88
users: ["admin", "dev", "qa"]
config: { retries: 3, active: true }
empty_var: ""
# missing_var is intentionally not defined to test 'undefined'

tasks:
- name: 1. Check if user_name is defined
debug:
msg: "user_name is defined"
when: user_name is defined

- name: 2. Check if missing_var is undefined
debug:
msg: "missing_var is not defined"
when: missing_var is not defined
ignore_errors: yes

- name: 3. Check if empty_var is none
debug:
msg: "empty_var is none"
when: empty_var is none

- name: 4. Check if email is a string
debug:
msg: "email is a string"
when: email is string

- name: 5. Check if age is a number
debug:
msg: "age is a number"
when: age is number

- name: 6. Check if score is even
debug:
msg: "score is even"
when: score is even

- name: 7. Check if score is odd
debug:
msg: "score is odd"
when: score is odd

- name: 8. Check if users is iterable
debug:
msg: "users is iterable"
when: users is iterable

- name: 9. Check if config is a mapping
debug:
msg: "config is a mapping (dictionary)"
when: config is mapping

- name: 10. Check if 'admin' is in users
debug:
msg: "admin exists in users"
when: 'admin' in users
EOF
```

# Step 4: Run the playbook
```bash
ansible-playbook -i inventory.ini jinja2-tests-playbook.yml
```

# =====================================
# 📚 EXPLANATIONS
# =====================================
# 1. `is defined`: Confirms variable is present.
# 2. `is not defined`: Checks missing or undefined variables.
# 3. `is none`: Checks for null or empty state.
# 4. `is string`: Ensures value is text.
# 5. `is number`: Confirms it's an integer or float.
# 6. `is even`: Validates even numbers.
# 7. `is odd`: Validates odd numbers.
# 8. `is iterable`: Checks if value can be looped.
# 9. `is mapping`: Checks if it's a dictionary.
# 10. `in`: Checks membership in a list or string.



# 🧠 Bonus Task: Modify one of the variables (e.g., make `score = 21`) and rerun the playbook to observe test behavior changes.
