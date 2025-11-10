# 🎓 Ansible Roles and Galaxy - Complete Training Guide

Welcome to the comprehensive Ansible Roles and Galaxy training! This guide takes you from beginner to advanced with hands-on labs using your existing OpenStack instance.

## 📚 Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Learning Path](#learning-path)
- [Course Structure](#course-structure)
- [Lab Environment](#lab-environment)
- [Getting Started](#getting-started)
- [Resources](#resources)

---

## 🎯 Overview

This training covers everything you need to know about Ansible Roles and Ansible Galaxy, from basic role creation to advanced production deployment strategies.

### What's Included

This training module contains:

1. **Comprehensive Theory** - Deep dive into roles and Galaxy (1626 lines)
2. **Hands-on Labs** - Progressive exercises from beginner to advanced (3 lab documents)
3. **Working Roles** - 6 production-ready roles (85+ files)
   - 2 Beginner roles (webserver, database)
   - 1 Intermediate role (nginx with Molecule tests)
   - 3 Advanced roles (OpenStack, HAProxy, Full Stack)
4. **Functional Playbooks** - 8 playbooks from basic to HA deployment
5. **Testing Framework** - Molecule integration with Docker
6. **CI/CD Pipelines** - GitHub Actions workflows for automation
7. **Documentation** - Comprehensive README files for all components
8. **Testing Script** - Automated validation with test-roles.sh

### Why Roles?

Roles provide:
- 🔄 **Reusability**: Write once, use everywhere
- 📦 **Organization**: Clean, modular code structure
- 🧪 **Testability**: Easy to test in isolation
- 🤝 **Sharing**: Distribute via Ansible Galaxy
- 🔧 **Maintainability**: Simple to update and debug

---

## 📋 Prerequisites

### Required Knowledge

- Basic Ansible experience (playbooks, tasks, variables)
- Linux command line proficiency
- Basic YAML syntax
- Git fundamentals

### Required Tools

```bash
# Ansible (version 2.9+)
ansible --version

# Python 3.6+
python3 --version

# Git
git --version

# Docker (for Molecule testing)
docker --version

# Optional but recommended
pip3 --version
```

### Install Required Packages

```bash
# Install Ansible and dependencies
pip3 install ansible ansible-lint yamllint

# Install Molecule with Docker driver
pip3 install molecule[docker]

# Install OpenStack SDK (for cloud testing)
pip3 install openstacksdk molecule-openstack

# Install additional tools
pip3 install jinja2-cli
```

### OpenStack Instance Setup

You should have:
- ✅ OpenStack instance accessible
- ✅ SSH access configured
- ✅ Python 3 installed on instance
- ✅ Sudo privileges
- ✅ clouds.yaml configured (for advanced labs)

---

## 🛤️ Learning Path

### Path 1: Fast Track (1-2 Days)
For experienced Ansible users who need quick role mastery:

1. **Theory** (1 hour) → `01-theory-roles-and-galaxy.md`
2. **Beginner Labs 1-2** (2 hours) → `02-beginner-labs.md`
3. **Intermediate Lab 5** (1 hour) → `03-intermediate-labs.md` (Molecule basics)
4. **Intermediate Lab 7** (1 hour) → `03-intermediate-labs.md` (Publishing)
5. **Practice Exercise** (2 hours) → Build your own role

### Path 2: Comprehensive (3-5 Days)
For thorough understanding and production readiness:

1. **Day 1: Foundations**
   - Theory (complete)
   - Beginner Labs 1-4
   - Practice exercises

2. **Day 2: Testing**
   - Intermediate Lab 5 (Molecule intro)
   - Intermediate Lab 6 (Multi-platform)
   - Intermediate Lab 9 (Advanced scenarios)

3. **Day 3: Publishing & Versioning**
   - Intermediate Lab 7 (Publishing)
   - Intermediate Lab 8 (Versioning)
   - GitHub integration

4. **Day 4: Advanced Topics**
   - Advanced Lab 10 (Dependencies)
   - Advanced Lab 11 (OpenStack)
   - Advanced Lab 12 (Security)

5. **Day 5: Production**
   - Advanced Lab 13 (CI/CD)
   - Practice exercises
   - Real-world project

### Path 3: Workshop Style (1 Day Intensive)
For team training sessions:

- **Morning (4 hours)**:
  - Theory overview (30 min)
  - Beginner Lab 1: Create first role (1 hour)
  - Beginner Lab 2: Templates (1 hour)
  - Intermediate Lab 5: Molecule (1.5 hours)

- **Afternoon (4 hours)**:
  - Intermediate Lab 7: Publishing (1 hour)
  - Advanced Lab 12: Security (1.5 hours)
  - Group project: Build role together (1.5 hours)

---

## 📖 Course Structure

### Module 1: Theory (1-2 hours)
**File**: `01-theory-roles-and-galaxy.md`

Complete reference covering:
- Role anatomy (all 8 directories)
- Best practices and conventions
- Molecule testing framework
- Ansible Galaxy ecosystem
- Publishing workflows
- Versioning strategies

**When to use**: Start here for complete understanding, or reference as needed.

### Module 2: Beginner Labs (3-4 hours)
**File**: `02-beginner-labs.md`

Four progressive hands-on labs:

| Lab | Topic | Time | Skills |
|-----|-------|------|--------|
| Lab 1 | First Role Creation | 45 min | ansible-galaxy init, basic tasks |
| Lab 2 | Templates & Variables | 1 hour | Jinja2, defaults, handlers |
| Lab 3 | Multi-Role Orchestration | 1 hour | Dependencies, meta.yml |
| Lab 4 | Role Organization | 45 min | ansible.cfg, role paths |

**Prerequisites**: Basic Ansible knowledge  
**Deliverable**: Working nginx role with templates

### Module 3: Intermediate Labs (6-8 hours)
**File**: `03-intermediate-labs.md`

Five comprehensive labs:

| Lab | Topic | Time | Skills |
|-----|-------|------|--------|
| Lab 5 | Molecule Testing | 2 hours | molecule, Docker driver, verify |
| Lab 6 | Multi-Platform Testing | 1.5 hours | Platform matrices, OS variables |
| Lab 7 | Publishing to Galaxy | 1.5 hours | GitHub, meta.yml, Galaxy import |
| Lab 8 | Versioning & Updates | 1 hour | SemVer, CHANGELOG, releases |
| Lab 9 | Advanced Molecule | 2 hours | Custom scenarios, dockerfiles |

**Prerequisites**: Completed beginner labs  
**Deliverable**: Published role on Ansible Galaxy

### Module 4: Advanced Labs (8-12 hours)
**File**: `04-advanced-labs.md`

Four production-focused labs:

| Lab | Topic | Time | Skills |
|-----|-------|------|--------|
| Lab 10 | Complex Dependencies | 2 hours | requirements.yml, collections |
| Lab 11 | OpenStack Testing | 2 hours | molecule-openstack, cloud testing |
| Lab 12 | Security & Vault | 3 hours | ansible-vault, security hardening |
| Lab 13 | CI/CD Pipelines | 3 hours | GitHub Actions, automated deployment |

**Prerequisites**: Intermediate labs completed  
**Deliverable**: Production-ready role with CI/CD

---

## 🧪 Lab Environment

### Option 1: Local Docker (Recommended for Testing)

```bash
# All labs 1-9 can use local Docker
cd ~/ansible_training/day5/ansible-roles-galaxy/roles/
molecule test
```

**Advantages**:
- ✅ Fast iteration
- ✅ No cloud costs
- ✅ Easy cleanup
- ✅ Offline capable

### Option 2: OpenStack Instance (Production-like)

```bash
# Labs 11+ use real OpenStack
export OS_CLOUD=devstack
molecule test -s openstack
```

**Advantages**:
- ✅ Real cloud environment
- ✅ Production testing
- ✅ Network testing
- ✅ Performance testing

### Directory Structure

```
~/ansible_training/day5/
├── ansible-roles-galaxy/          # Training materials
│   ├── 01-theory-roles-and-galaxy.md
│   ├── 02-beginner-labs.md
│   ├── 03-intermediate-labs.md
│   ├── 04-advanced-labs.md
│   └── README.md (this file)
│
└── roles/                         # Your work directory
    ├── custom/                    # Roles you create
    │   ├── nginx-basic/
    │   ├── apache-molecule/
    │   └── webapp-stack/
    │
    ├── galaxy/                    # Downloaded roles
    │   └── geerlingguy.*/
    │
    └── requirements.yml           # Role dependencies
```

---

## 🚀 Getting Started

### Quick Start (15 minutes)

1. **Set up workspace**:
```bash
cd ~/ansible_training/day5/ansible-roles-galaxy/
mkdir -p roles/custom roles/galaxy
cd roles/
```

2. **Create your first role**:
```bash
ansible-galaxy init --init-path custom/ my-first-role
cd custom/my-first-role
ls -la
```

3. **Add a simple task** (`tasks/main.yml`):
```yaml
---
- name: Install nginx
  package:
    name: nginx
    state: present
```

4. **Test it**:
```yaml
# test-playbook.yml
---
- hosts: localhost
  roles:
    - my-first-role
```

```bash
ansible-playbook test-playbook.yml --ask-become-pass
```

5. **Success!** You've created your first role!

### Next Steps

Choose your path:
- 📘 **Thorough learner**: Read `01-theory-roles-and-galaxy.md`
- 🏃 **Action learner**: Jump to `02-beginner-labs.md`
- 🎯 **Goal-oriented**: Pick specific labs for your needs

---

## 📚 Resources

### Official Documentation
- [Ansible Roles Documentation](https://docs.ansible.com/ansible/latest/user_guide/playbooks_reuse_roles.html)
- [Ansible Galaxy](https://galaxy.ansible.com/)
- [Molecule Documentation](https://molecule.readthedocs.io/)

### Community Roles (Examples)
- [geerlingguy roles](https://galaxy.ansible.com/geerlingguy) - High-quality role examples
- [debops](https://galaxy.ansible.com/debops) - Data center automation
- [robertdebock](https://galaxy.ansible.com/robertdebock) - Comprehensive role collection

### Tools
- [ansible-lint](https://ansible-lint.readthedocs.io/) - Best practices enforcement
- [yamllint](https://yamllint.readthedocs.io/) - YAML syntax checking
- [Molecule](https://molecule.readthedocs.io/) - Role testing framework

### Best Practices
- [Ansible Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)
- [Role Development Best Practices](https://galaxy.ansible.com/docs/contributing/creating_role.html)

---

## 🎓 Certification Prep

This training aligns with:
- ✅ Red Hat Certified Specialist in Ansible Automation
- ✅ Ansible Content Development Skills

Key exam topics covered:
- Role creation and structure
- Role dependencies
- Using Galaxy
- Variables and defaults
- Testing and validation

---

## 🤝 Getting Help

### During Labs

1. **Check the theory**: Each lab references theory sections
2. **Read error messages**: Most issues have clear error messages
3. **Use debug**: Add `-vvv` for verbose output
4. **Check syntax**: Run `ansible-playbook --syntax-check`
5. **Consult documentation**: Official docs are comprehensive

### Common Issues

**Issue**: `role not found`  
**Solution**: Check role path in `ansible.cfg`:
```ini
[defaults]
roles_path = ./roles:~/.ansible/roles:/usr/share/ansible/roles
```

**Issue**: `Molecule test fails`  
**Solution**: Check Docker is running:
```bash
docker ps
systemctl status docker
```

**Issue**: `Galaxy import fails`  
**Solution**: Verify `meta/main.yml` is complete and valid

### Additional Support

- **Issues**: Document problems for later review
- **Community**: Join #ansible on Libera.Chat IRC
- **Stack Overflow**: Tag questions with `ansible` and `ansible-role`

---

## 📊 Progress Tracking

### Beginner Level Checklist
- [ ] Understand role structure (8 directories)
- [ ] Create role with `ansible-galaxy init`
- [ ] Write tasks with proper YAML syntax
- [ ] Use variables in `defaults/main.yml`
- [ ] Create Jinja2 templates
- [ ] Write handlers for service management
- [ ] Document role in README.md
- [ ] Use roles in playbooks

### Intermediate Level Checklist
- [ ] Install and configure Molecule
- [ ] Write Molecule test scenarios
- [ ] Test on multiple platforms
- [ ] Create comprehensive meta.yml
- [ ] Publish role to Ansible Galaxy
- [ ] Use semantic versioning
- [ ] Maintain CHANGELOG.md
- [ ] Configure GitHub webhooks

### Advanced Level Checklist
- [ ] Manage complex role dependencies
- [ ] Use Ansible Collections
- [ ] Test on OpenStack instances
- [ ] Implement security with Vault
- [ ] Create CI/CD pipelines
- [ ] Use GitHub Actions for automation
- [ ] Write comprehensive tests
- [ ] Deploy to production

---

## 🎯 Learning Objectives

By completing this training, you will be able to:

1. **Design** well-structured, maintainable Ansible roles
2. **Develop** roles following best practices and conventions
3. **Test** roles comprehensively using Molecule
4. **Publish** roles to Ansible Galaxy for community use
5. **Version** roles using semantic versioning
6. **Secure** roles using Ansible Vault
7. **Automate** testing and deployment with CI/CD
8. **Deploy** roles to production environments

---

## 📅 Suggested Schedule

### Self-Paced (5 days)
- **Day 1**: Theory + Beginner Labs (4-5 hours)
- **Day 2**: Intermediate Labs 5-6 (4-5 hours)
- **Day 3**: Intermediate Labs 7-9 (4-5 hours)
- **Day 4**: Advanced Labs 10-12 (4-5 hours)
- **Day 5**: Advanced Lab 13 + Practice (4-5 hours)

### Intensive Workshop (2 days)
- **Day 1 Morning**: Theory + Labs 1-2
- **Day 1 Afternoon**: Labs 3-4 + Lab 5
- **Day 2 Morning**: Labs 6-7
- **Day 2 Afternoon**: Lab 12 + Practice

### Weekend Course (2 weekends)
- **Weekend 1**: Beginner + Intermediate Labs
- **Weekend 2**: Advanced Labs + Practice

---

## ✅ Success Criteria

You've mastered Ansible Roles when you can:

1. ✅ Create a role from scratch in under 10 minutes
2. ✅ Write Molecule tests for any role
3. ✅ Publish and maintain roles on Galaxy
4. ✅ Implement security best practices
5. ✅ Set up complete CI/CD pipeline
6. ✅ Debug role issues efficiently
7. ✅ Contribute to community roles
8. ✅ Design role architectures for complex systems

---

## 🎉 Final Project Ideas

Apply your skills:

1. **LEMP Stack Role**: Complete web server setup
2. **Monitoring Role**: Prometheus + Grafana deployment
3. **Database Cluster**: PostgreSQL with replication
4. **Container Platform**: Docker Swarm or K8s setup
5. **CI/CD Platform**: Jenkins or GitLab CI deployment
6. **Security Hardening**: CIS benchmark compliance role

---

## 📝 Notes

- All labs are hands-on and require actual execution
- Code examples are production-ready templates
- Security practices are industry-standard
- Best practices follow Ansible official guidelines
- OpenStack labs require configured instance access

---

## 🔄 Updates

This training material is regularly updated. Check:
- Latest Ansible versions
- New Molecule features
- Galaxy platform changes
- Security updates

---

**Ready to start? Jump to: [01-theory-roles-and-galaxy.md](01-theory-roles-and-galaxy.md)**

**Questions? Check the Getting Help section above.**

**Happy role building! 🚀**
