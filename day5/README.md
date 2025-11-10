# 🎓 Day 5: Ansible Playbook Best Practices

## 📚 Topics Covered

1. **Directory Layout** - Proper project structure for scalability
2. **Use Dynamic Inventory With Clouds** - AWS, Azure, OpenStack integration
3. **How to Differentiate Staging vs Production** - Environment separation
4. **Group And Host Variables** - Variable precedence and organization
5. **Top Level Playbooks Are Separated By Server Type** - Modular design patterns

## 📂 Lab Structure

```
day5/
├── README.md (this file)
├── 01-directory-layout.md
├── 02-dynamic-inventory.md
├── 03-staging-vs-production.md
├── 04-group-host-variables.md
├── 05-top-level-playbooks.md
├── exercise-day5.md
└── best-practices-lab/
    ├── ansible.cfg
    ├── site.yml
    ├── webservers.yml
    ├── dbservers.yml
    ├── loadbalancers.yml
    ├── production
    ├── staging
    ├── group_vars/
    ├── host_vars/
    ├── inventories/
    ├── roles/
    └── cloud-inventory/
```

## 🎯 Learning Objectives

By the end of this day, you will:
- ✅ Understand and implement Ansible best practice directory structures
- ✅ Configure and use dynamic inventory for cloud providers
- ✅ Properly separate staging and production environments
- ✅ Master variable precedence and organization
- ✅ Create maintainable, modular playbook architectures
- ✅ Implement real-world enterprise patterns

## ⚙️ Prerequisites

- Completed Day 1-4 materials
- Ansible 2.9+ installed
- Basic understanding of YAML, roles, and vault
- Access to a cloud provider (optional for dynamic inventory)
- 2-3 Linux VMs or Docker containers for testing

## 🚀 Getting Started

1. Review each topic document in order (01 through 05)
2. Follow the hands-on examples in `best-practices-lab/`
3. Complete the comprehensive exercise in `exercise-day5.md`
4. Test your knowledge with the challenge scenarios

## 📖 Quick Reference

### Ansible Best Practices Directory Layout
```
production              # inventory file for production
staging                 # inventory file for staging
group_vars/
   group1.yml           # variables for group1
   group2.yml
host_vars/
   hostname1.yml        # variables for hostname1
   hostname2.yml
library/                # custom modules (optional)
module_utils/           # custom module utilities (optional)
filter_plugins/         # custom filter plugins (optional)
site.yml                # master playbook
webservers.yml          # playbook for webserver tier
dbservers.yml           # playbook for database tier
roles/
    common/             # common role
    webserver/          # webserver role
    database/           # database role
```

## 🔗 Additional Resources

- [Ansible Best Practices Guide](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)
- [Directory Layout Documentation](https://docs.ansible.com/ansible/latest/user_guide/sample_setup.html)
- [Dynamic Inventory Guide](https://docs.ansible.com/ansible/latest/user_guide/intro_dynamic_inventory.html)

---

**Duration:** 2-3 hours
**Difficulty:** Intermediate to Advanced
**Lab Environment:** Multi-server setup recommended
