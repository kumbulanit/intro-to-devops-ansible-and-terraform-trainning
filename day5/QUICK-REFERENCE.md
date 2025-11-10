# 📖 Day 5 Quick Reference Guide

## 🎯 Key Concepts Summary

### 1. Directory Layout Best Practices

```text
project/
├── ansible.cfg
├── inventories/
│   ├── production/
│   │   ├── hosts
│   │   ├── group_vars/
│   │   └── host_vars/
│   └── staging/
│       ├── hosts
│       ├── group_vars/
│       └── host_vars/
├── site.yml
├── webservers.yml
├── dbservers.yml
└── roles/
```

### 2. Variable Precedence (Low to High)

1. Role defaults
2. Inventory file group vars
3. group_vars/all
4. group_vars/[group]
5. Inventory file host vars
6. host_vars/[host]
7. Play vars
8. Role vars
9. Task vars
10. Extra vars (-e)

### 3. Dynamic Inventory

**OpenStack Example:**
```yaml
# inventories/openstack.yml
plugin: openstack.cloud.openstack
clouds:
  - devstack
keyed_groups:
  - key: metadata.environment
    prefix: env
  - key: metadata.role
    prefix: role
```

**Usage:**
```bash
ansible-inventory -i inventories/openstack.yml --list
ansible-playbook -i inventories/openstack.yml site.yml
```

### 4. Environment Separation

**Key Strategies:**
- Separate inventory directories
- Environment-specific variables
- Different vault passwords
- Safety prompts for production

**Example Production Safety:**
```yaml
- name: Production check
  pause:
    prompt: "Deploy to PRODUCTION? (Ctrl+C to abort)"
  when: environment == "production"
```

### 5. Top-Level Playbooks

**Master Playbook (site.yml):**
```yaml
---
- import_playbook: common.yml
  tags: [common]
- import_playbook: dbservers.yml
  tags: [database]
- import_playbook: webservers.yml
  tags: [web]
```

**Usage:**
```bash
# Deploy everything
ansible-playbook site.yml

# Deploy only web servers
ansible-playbook site.yml --tags web

# Skip database
ansible-playbook site.yml --skip-tags database
```

## 🚀 Common Commands

### Inventory Commands
```bash
# List all hosts
ansible-inventory -i production --list

# Show inventory graph
ansible-inventory -i production --graph

# List specific group
ansible webservers -i production --list-hosts
```

### Playbook Commands
```bash
# Syntax check
ansible-playbook site.yml --syntax-check

# Dry run
ansible-playbook site.yml --check

# List tasks
ansible-playbook site.yml --list-tasks

# List tags
ansible-playbook site.yml --list-tags

# Run with specific tags
ansible-playbook site.yml --tags "web,db"

# Skip tags
ansible-playbook site.yml --skip-tags monitoring

# Limit to specific hosts
ansible-playbook site.yml --limit web1.example.com

# Extra variables
ansible-playbook site.yml -e "version=1.2.3"
```

### Vault Commands
```bash
# Create vault file
ansible-vault create group_vars/all/vault.yml

# Edit vault file
ansible-vault edit group_vars/all/vault.yml

# View vault file
ansible-vault view group_vars/all/vault.yml

# Encrypt existing file
ansible-vault encrypt group_vars/all/secrets.yml

# Decrypt file
ansible-vault decrypt group_vars/all/secrets.yml

# Change vault password
ansible-vault rekey group_vars/all/vault.yml

# Use vault password file
ansible-playbook site.yml --vault-password-file .vault_pass
```

### Variable Commands
```bash
# Show variable for host
ansible web1 -m debug -a "var=http_port"

# Show all variables for host
ansible web1 -m debug -a "var=hostvars[inventory_hostname]"

# Test variable precedence
ansible-playbook test.yml -e "test_var=extra_vars_win"
```

## 📁 File Templates

### ansible.cfg
```ini
[defaults]
inventory = ./inventories/production/hosts
roles_path = ./roles
host_key_checking = False
retry_files_enabled = False

[privilege_escalation]
become = True
become_method = sudo
```

### Master Playbook
```yaml
---
- import_playbook: common.yml
  tags: [common, always]

- import_playbook: webservers.yml
  tags: [web]

- import_playbook: dbservers.yml
  tags: [db]
```

### Group Variables
```yaml
---
# group_vars/webservers.yml
http_port: 80
nginx_worker_processes: 4
app_name: myapp
```

### Host Variables
```yaml
---
# host_vars/web1.example.com.yml
server_id: 1
nginx_worker_processes: 8  # Override
is_primary: true
```

## 🔧 Troubleshooting

### Check Variable Precedence
```bash
ansible web1 -m debug -a "var=varname" -i production
```

### Verbose Output
```bash
ansible-playbook site.yml -vvv
```

### Check Facts
```bash
ansible all -m setup -i production
```

### Test Connection
```bash
ansible all -m ping -i production
```

### Validate Vault
```bash
ansible-vault view group_vars/all/vault.yml
```

## 💡 Best Practices Checklist

**Project Structure:**
- [ ] Use recommended directory layout
- [ ] Separate inventories per environment
- [ ] Organize variables in group_vars/host_vars
- [ ] Use ansible.cfg for project settings

**Variable Management:**
- [ ] Use descriptive variable names
- [ ] Document all variables
- [ ] Separate secrets into vault files
- [ ] Follow variable precedence rules

**Environment Separation:**
- [ ] Separate production and staging completely
- [ ] Use different vault passwords
- [ ] Implement production safety checks
- [ ] Test in staging first

**Playbooks:**
- [ ] Create master site.yml
- [ ] Separate playbooks by server type
- [ ] Use meaningful tags
- [ ] Include pre_tasks and post_tasks
- [ ] Add verification steps

**Security:**
- [ ] Encrypt all secrets with vault
- [ ] Use separate vault passwords per environment
- [ ] Never commit vault passwords to git
- [ ] Use .gitignore for sensitive files

**Deployment:**
- [ ] Always run --syntax-check first
- [ ] Use --check for dry runs
- [ ] Deploy to staging before production
- [ ] Use deployment wrapper scripts
- [ ] Log production deployments

## 📚 Additional Resources

- [Ansible Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)
- [Ansible Vault Guide](https://docs.ansible.com/ansible/latest/user_guide/vault.html)
- [Dynamic Inventory](https://docs.ansible.com/ansible/latest/user_guide/intro_dynamic_inventory.html)
- [Variable Precedence](https://docs.ansible.com/ansible/latest/user_guide/playbooks_variables.html#variable-precedence-where-should-i-put-a-variable)

---

**Need Help?**
- Review the topic markdown files (01-05)
- Check the complete exercise in exercise-day5.md
- Refer to Day 1-4 materials for foundational concepts
