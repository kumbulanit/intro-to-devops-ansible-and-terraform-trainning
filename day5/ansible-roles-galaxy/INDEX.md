# 📝 Day 5 Navigation Index

Quick access to all Day 5 materials for Ansible Roles and Galaxy training.

## 🚀 Start Here

1. **[QUICKSTART.md](./QUICKSTART.md)** - Get up and running in 5 minutes
2. **[SUMMARY.md](./SUMMARY.md)** - Complete overview of all created content
3. **[README.md](./README.md)** - Full training guide with learning paths

## 📖 Theory & Documentation

| Document | Lines | Description | Time |
|----------|-------|-------------|------|
| [01-theory-roles-and-galaxy.md](./01-theory-roles-and-galaxy.md) | 1626 | Complete theoretical foundation | 2-3h |
| [02-beginner-labs.md](./02-beginner-labs.md) | ~800 | Hands-on beginner exercises | 3-4h |
| [03-intermediate-labs.md](./03-intermediate-labs.md) | 1431 | Molecule testing & Galaxy | 6-8h |
| [04-advanced-labs.md](./04-advanced-labs.md) | ~1000 | Complex scenarios | 8-12h |
| [05-extra-challenges.md](./05-extra-challenges.md) | ~500 | Bonus exercises | Variable |

**Total Theory**: ~5,400 lines | ~20-30 hours

## 🎯 Working Roles

### Beginner Roles
- **[beginner/webserver](./roles/beginner/webserver/)** - Apache/Nginx deployment (8 files)
- **[beginner/database](./roles/beginner/database/)** - PostgreSQL setup (8 files)

### Intermediate Roles
- **[intermediate/nginx-tested](./roles/intermediate/nginx-tested/)** - Molecule-tested Nginx (11 files)

### Advanced Roles
- **[advanced/openstack-vm](./roles/advanced/openstack-vm/)** - Cloud VM provisioning (6 files)
- **[advanced/haproxy-lb](./roles/advanced/haproxy-lb/)** - Load balancer (10 files)
- **[advanced/fullstack-app](./roles/advanced/fullstack-app/)** - Full stack with dependencies (10 files)

**Total Roles**: 6 complete roles | 53 files

## 📜 Playbooks

| # | Playbook | Lines | Level | Description |
|---|----------|-------|-------|-------------|
| 01 | [webserver-basic.yml](./playbooks/01-webserver-basic.yml) | 32 | Beginner | Basic web server |
| 02 | [database-basic.yml](./playbooks/02-database-basic.yml) | 50 | Beginner | PostgreSQL setup |
| 03 | [complete-stack.yml](./playbooks/03-complete-stack.yml) | 70 | Beginner | Multi-tier stack |
| 04 | [nginx-molecule-tested.yml](./playbooks/04-nginx-molecule-tested.yml) | 77 | Intermediate | Tested role deployment |
| 05 | [openstack-complete-stack.yml](./playbooks/05-openstack-complete-stack.yml) | 221 | Advanced | Full cloud infrastructure |
| 06 | [haproxy-loadbalancer.yml](./playbooks/06-haproxy-loadbalancer.yml) | 110 | Advanced | Load balancer |
| 07 | [complete-ha-stack.yml](./playbooks/07-complete-ha-stack.yml) | 195 | Advanced | HA infrastructure |
| 08 | [fullstack-with-dependencies.yml](./playbooks/08-fullstack-with-dependencies.yml) | 140 | Advanced | Role dependencies |

**Total Playbooks**: 8 functional playbooks | 895 lines

**Also Available**: 
- [playbooks/inventory.ini](./playbooks/inventory.ini) - Inventory template
- [playbooks/README.md](./playbooks/README.md) - Playbook documentation

## 🧪 Testing & CI/CD

- **[test-roles.sh](./test-roles.sh)** - Testing automation script (200+ lines)
- **[.github/workflows/molecule.yml](./.github/workflows/molecule.yml)** - CI testing pipeline
- **[.github/workflows/release.yml](./.github/workflows/release.yml)** - Galaxy publishing workflow

## 📊 Quick Stats

- **Total Files**: 85+
- **Total Lines of Code**: 8,000+
- **Documentation Pages**: 5
- **Working Roles**: 6
- **Playbooks**: 8
- **Templates**: 15+
- **Test Suites**: 1 complete (Molecule)
- **CI/CD Workflows**: 2

## 🎓 Recommended Learning Sequence

### Week 1: Foundations
```
Day 1: 01-theory-roles-and-galaxy.md (sections 1-5)
Day 2: 01-theory-roles-and-galaxy.md (sections 6-10)
Day 3: 02-beginner-labs.md (Labs 1-3)
Day 4: Run playbooks 01-02
Day 5: 02-beginner-labs.md (Labs 4-6) + playbook 03
```

### Week 2: Intermediate Skills
```
Day 1: 03-intermediate-labs.md (Labs 1-2)
Day 2: 03-intermediate-labs.md (Lab 3 - Molecule)
Day 3: Run playbook 04, explore nginx-tested role
Day 4: 03-intermediate-labs.md (Labs 4-5)
Day 5: Practice: Modify beginner roles, add tests
```

### Week 3: Advanced Techniques
```
Day 1: 04-advanced-labs.md (Labs 1-2)
Day 2: OpenStack setup + playbook 05
Day 3: 04-advanced-labs.md (Lab 3-4) + playbook 06
Day 4: Deploy HA stack (playbook 07)
Day 5: Role dependencies (playbook 08)
```

### Week 4: Mastery & Practice
```
Day 1: 05-extra-challenges.md (Challenges 1-2)
Day 2: CI/CD setup with GitHub Actions
Day 3: 05-extra-challenges.md (Challenge 3)
Day 4: Create custom role from scratch
Day 5: Review, document, publish to Galaxy
```

## 🔍 Find Content By Topic

### Role Structure
- Theory: 01-theory (Section 2)
- Lab: 02-beginner-labs (Lab 1)
- Example: roles/beginner/webserver/

### Ansible Galaxy
- Theory: 01-theory (Section 4)
- Lab: 03-intermediate-labs (Lab 5)
- CI/CD: .github/workflows/release.yml

### Molecule Testing
- Theory: 01-theory (Section 5)
- Lab: 03-intermediate-labs (Lab 3)
- Example: roles/intermediate/nginx-tested/

### Role Dependencies
- Theory: 01-theory (Section 3.4)
- Lab: 04-advanced-labs (Lab 2)
- Example: roles/advanced/fullstack-app/meta/main.yml
- Playbook: 08-fullstack-with-dependencies.yml

### OpenStack Integration
- Theory: 01-theory (Section 9)
- Lab: 04-advanced-labs (Lab 1)
- Role: roles/advanced/openstack-vm/
- Playbooks: 05, 07

### Load Balancing
- Theory: 01-theory (Section 8)
- Lab: 04-advanced-labs (Lab 3)
- Role: roles/advanced/haproxy-lb/
- Playbook: 06, 07

### CI/CD Integration
- Theory: 01-theory (Section 10)
- Lab: 04-advanced-labs (Lab 4)
- Workflows: .github/workflows/

## 🛠️ Quick Commands

### Run Tests
```bash
# All tests
./test-roles.sh all

# Specific test
./test-roles.sh syntax
./test-roles.sh molecule
```

### Run Playbooks
```bash
# Basic
ansible-playbook -i playbooks/inventory.ini playbooks/01-webserver-basic.yml

# With variables
ansible-playbook playbooks/02-database-basic.yml --extra-vars "db_password=secret"

# OpenStack
ansible-playbook playbooks/05-openstack-complete-stack.yml
```

### Molecule Testing
```bash
cd roles/intermediate/nginx-tested
molecule test
```

### Install Collections
```bash
ansible-galaxy collection install openstack.cloud
```

## 📞 Getting Help

1. **Check Documentation**: Each role has a detailed README.md
2. **Run Tests**: Use `test-roles.sh` to validate setup
3. **Verbose Mode**: Add `-vvv` to ansible-playbook for debugging
4. **QUICKSTART**: Start with QUICKSTART.md if you're lost
5. **SUMMARY**: Check SUMMARY.md for complete overview

## ✅ Completion Checklist

Track your progress:

- [ ] Read QUICKSTART.md
- [ ] Read SUMMARY.md
- [ ] Complete 01-theory (all sections)
- [ ] Run beginner labs (02-beginner-labs.md)
- [ ] Deploy playbooks 01-03
- [ ] Complete intermediate labs (03-intermediate-labs.md)
- [ ] Run Molecule tests
- [ ] Deploy playbooks 04-05
- [ ] Complete advanced labs (04-advanced-labs.md)
- [ ] Deploy playbooks 06-08
- [ ] Set up CI/CD pipeline
- [ ] Create custom role
- [ ] Publish to Galaxy
- [ ] Complete extra challenges (05-extra-challenges.md)

## 🎉 Next Steps After Completion

1. Build a production role for your environment
2. Contribute to Ansible Galaxy community
3. Mentor others learning Ansible
4. Explore advanced topics (AWX, Ansible Tower)
5. Integrate with other tools (Terraform, Jenkins)

---

**Total Training Time**: 3-4 weeks (self-paced) | 40-60 hours
**Skill Level**: Beginner → Advanced
**Hands-on Focus**: 70% practical, 30% theory

**Last Updated**: 2024
**Version**: 1.0.0
