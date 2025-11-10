# 🏢 Ansible Tower/AWX and CI/CD Integration

## � Overview

This module covers enterprise automation orchestration tools:
- **Ansible Tower/AWX**: Web-based automation platform
- **Jenkins**: CI/CD integration with Ansible
- **GitHub**: Version control and GitOps workflows
- **OpenStack Integration**: Cloud infrastructure automation with complete configuration

---

## 📚 Topics

### 1. **Introduction to Ansible Tower/AWX** (`01-ansible-tower-awx-introduction.md`)
- What is Tower/AWX and why use it
- Key features: Web UI, RBAC, Scheduling, Workflows
- Architecture overview
- Tower vs AWX detailed comparison
- Core concepts: Organizations, Projects, Inventories, Job Templates

### 2. **Jenkins vs Ansible Tower** (`02-jenkins-vs-tower.md`)
- Comprehensive feature comparison
- When to choose Jenkins vs AWX
- Cost analysis for different team sizes
- Integration patterns and best practices
- Real-world use cases and decision matrix

### 3. **GitHub Integration** (`03-github-integration.md`)
- Setting up GitHub credentials and webhooks
- Automated playbook deployment on push
- Pull request workflows with validation
- Jenkins multibranch pipelines
- AWX project synchronization
- Secrets management (Vault integration)

### 4. **Installation - Local Ubuntu** (`04-awx-installation-local.md`)
- **Method 1**: AWX Operator with Minikube (official)
- **Method 2**: Docker Compose standalone (simplified)
- Step-by-step installation guide
- System requirements and dependencies
- Troubleshooting common issues
- Post-installation configuration

### 5. **Installation - OpenStack VM** (`05-awx-installation-openstack.md`)
- Complete `clouds.yaml` configuration examples
- Automated AWX deployment with Ansible
- OpenStack security groups and networking
- Floating IP assignment
- Dynamic inventory from OpenStack
- Integration with AWX credentials
- Complete working playbook included

### 6. **Comprehensive Exercise** (`06-comprehensive-exercise.md`)
- **Full three-tier application deployment**:
  - HAProxy load balancer
  - Nginx web servers (2x)
  - PostgreSQL database
- OpenStack infrastructure provisioning
- GitHub repository structure
- AWX job templates and workflows
- Jenkins CI/CD pipeline (optional)
- Complete testing procedures
- Bonus challenges

---

## 🎯 Learning Objectives

By the end of this module, you will:

- ✅ Understand when to use Tower/AWX vs Jenkins
- ✅ Install AWX on local machine **OR** OpenStack VM
- ✅ Configure OpenStack credentials (clouds.yaml)
- ✅ Integrate Ansible with GitHub for GitOps
- ✅ Create job templates and workflows in AWX
- ✅ Configure dynamic inventory from OpenStack
- ✅ Build CI/CD pipelines for Ansible automation
- ✅ Deploy complete three-tier application stacks
- ✅ Implement webhook-based automation
- ✅ Manage secrets with Ansible Vault in AWX

---

## 📋 Prerequisites

### Knowledge Requirements

- ✅ Completed Day 1-4 training
- ✅ Understanding of:
  - Ansible playbooks and roles
  - OpenStack basics (clouds.yaml, instances, networks)
  - Git and GitHub workflows
  - Linux system administration
  - Docker basics (helpful but not required)

### System Requirements

**For Local Installation:**
- Ubuntu 20.04 or 22.04 LTS
- 8GB RAM (minimum 4GB)
- 4 CPU cores
- 20GB free disk space
- Docker and Docker Compose

**For OpenStack Installation:**
- Access to OpenStack environment
- Available quota: 4 vCPUs, 8GB RAM, 40GB disk
- Floating IP available
- SSH key pair

**General:**
- GitHub account
- Ansible 2.9+ installed locally
- Python 3.8+ with openstacksdk

---

## 🚀 Getting Started

### Recommended Learning Path

1. **Read Introduction** (30 min)
   - Understand AWX features and architecture
   - Review Tower vs AWX comparison

2. **Study Jenkins Comparison** (30 min)
   - Learn when to use each tool
   - Understand cost implications
   - Review integration patterns

3. **Learn GitHub Integration** (1 hour)
   - Webhook setup
   - CI/CD workflows
   - Secrets management

4. **Choose Installation Method** (2 hours)
   - **Option A**: Local Ubuntu (easier for testing)
   - **Option B**: OpenStack VM (production-like)
   - Follow step-by-step guide
   - Complete verification steps

5. **Complete Exercise** (3-4 hours)
   - Deploy three-tier application
   - Configure AWX job templates
   - Test end-to-end automation
   - Implement optional Jenkins integration

**Total Time**: 7-8 hours

---

## 📁 Files in This Module

```
ansible-tower-awx/
├── README.md                              # This file - Overview and getting started
├── 01-ansible-tower-awx-introduction.md   # AWX concepts and architecture
├── 02-jenkins-vs-tower.md                 # Detailed comparison guide
├── 03-github-integration.md               # Git workflows and webhooks
├── 04-awx-installation-local.md           # Local Ubuntu installation
├── 05-awx-installation-openstack.md       # OpenStack deployment with clouds.yaml
└── 06-comprehensive-exercise.md           # Complete three-tier app project
```

---

## 🌟 Key Features of This Module

### OpenStack Integration

- **Complete clouds.yaml examples** for DevStack and production
- **Automated VM provisioning** with security groups
- **Dynamic inventory** configuration for AWX
- **Floating IP management** and networking setup
- **Working deployment playbooks** ready to use

### AWX/Tower Coverage

- **Two installation methods**: Minikube + Docker Compose options
- **Job templates** and workflow creation
- **RBAC** and credential management
- **Project synchronization** with GitHub
- **Survey forms** for user input
- **Webhook triggers** for automation

### Jenkins Integration

- **Jenkinsfile examples** for Ansible automation
- **Multibranch pipelines** with GitHub
- **Ansible plugin** configuration
- **Credential management** in Jenkins
- **Pipeline-as-code** best practices

### Real-World Exercise

- **Production-ready architecture**: Load balancer + Web + Database
- **Complete automation**: From infrastructure to application
- **GitHub repository structure**: Industry-standard organization
- **Testing procedures**: Validation at every step
- **Bonus challenges**: Advanced scenarios

---

## ⏱️ Time Allocation

| Activity | Duration | Notes |
|----------|----------|-------|
| Topics 1-3 (Theory) | 2 hours | Concepts and comparison |
| Topic 4 (Local Install) | 1-2 hours | If choosing local |
| Topic 5 (OpenStack Install) | 1-2 hours | If choosing OpenStack |
| Topic 6 (Exercise) | 3-4 hours | Complete project |
| **Total** | **7-8 hours** | Can be split over days |

---

## 🔗 Useful Resources

### Official Documentation

- [AWX GitHub Repository](https://github.com/ansible/awx)
- [Ansible Tower Documentation](https://docs.ansible.com/ansible-tower/)
- [AWX Operator Guide](https://github.com/ansible/awx-operator)
- [OpenStack Ansible Collection](https://galaxy.ansible.com/openstack/cloud)

### Tools and Plugins

- [Jenkins Ansible Plugin](https://plugins.jenkins.io/ansible/)
- [OpenStack SDK Python](https://pypi.org/project/openstacksdk/)
- [Docker Compose](https://docs.docker.com/compose/)
- [Minikube](https://minikube.sigs.k8s.io/)

### Learning Resources

- [AWX YouTube Channel](https://www.youtube.com/@AnsiblePilot)
- [Ansible Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)
- [Jenkins Pipeline Examples](https://www.jenkins.io/doc/pipeline/examples/)

---

## 💡 Tips for Success

### Installation Tips

1. **Start with Local**: If new to AWX, begin with local installation
2. **Check Requirements**: Ensure system meets minimum specs
3. **Read Logs**: AWX provides detailed logs for troubleshooting
4. **Save Passwords**: Document all credentials securely
5. **Backup clouds.yaml**: Keep OpenStack configs version-controlled

### Development Tips

1. **Use Git**: Version control ALL playbooks and configurations
2. **Test Locally First**: Validate playbooks before running in AWX
3. **Incremental Testing**: Test each component individually
4. **Use Check Mode**: Always dry-run with `--check` first
5. **Leverage Vault**: Never commit plaintext secrets

### AWX Best Practices

1. **Organizations**: Create separate orgs for different teams
2. **Projects**: Keep projects small and focused
3. **Credentials**: Use credential types appropriately
4. **Surveys**: Add surveys for user-friendly job launches
5. **Workflows**: Chain jobs together for complex deployments

### OpenStack Tips

1. **clouds.yaml Location**: Keep in `~/.config/openstack/`
2. **Test Connection**: Use `openstack server list` to verify
3. **Quota Management**: Check available quota before provisioning
4. **Security Groups**: Create specific rules, avoid 0.0.0.0/0
5. **Floating IPs**: Manage carefully, they're limited resources

---

## 🎓 Next Steps After This Module

### Immediate Next Steps

1. **Experiment with Workflows**: Create complex multi-job workflows
2. **Add Notifications**: Configure Slack/email alerts
3. **Implement RBAC**: Create teams with specific permissions
4. **Schedule Jobs**: Set up recurring deployments
5. **API Integration**: Use AWX REST API for automation

### Advanced Topics

- **Custom Credential Types**: Create organization-specific credentials
- **Ansible Collections**: Integrate with namespace collections
- **Container Groups**: Run jobs in isolated containers
- **High Availability**: Deploy AWX in HA configuration
- **Kubernetes Integration**: Deploy to Kubernetes clusters

### Related Technologies

- **Terraform**: Infrastructure provisioning before Ansible
- **Kubernetes**: Container orchestration platform
- **Prometheus/Grafana**: Monitoring and alerting
- **Vault (HashiCorp)**: Advanced secrets management
- **GitLab CI**: Alternative to Jenkins

---

## 🐛 Troubleshooting Resources

### Common Issues

**AWX won't start**
- Check Docker containers: `docker ps`
- View logs: `docker logs awx-web`
- Verify memory: AWX needs minimum 4GB RAM

**OpenStack connection fails**
- Verify clouds.yaml syntax
- Test with OpenStack CLI first
- Check network connectivity to OpenStack API

**GitHub sync issues**
- Verify credentials are correct
- Check repository URL (https vs ssh)
- Ensure branch name is correct

**Job failures**
- Check job output in AWX UI
- Verify inventory is synchronized
- Test SSH connectivity manually
- Check credential permissions

### Getting Help

- **AWX Google Group**: Active community support
- **Stack Overflow**: Tag questions with `ansible-tower` or `awx`
- **GitHub Issues**: Report bugs to AWX repository
- **Reddit**: r/ansible community

---

## 📝 Feedback and Contributions

This training material is designed to be practical and hands-on. If you:
- Find errors or outdated information
- Have suggestions for improvements
- Want to share your success stories
- Need clarification on topics

Please provide feedback to improve this training!

---

## 🏆 Learning Outcomes

Upon successful completion, you will have:

- ✅ **Installed AWX** on your chosen platform
- ✅ **Configured OpenStack integration** with dynamic inventory
- ✅ **Set up GitHub workflows** with webhook automation
- ✅ **Created job templates** for common tasks
- ✅ **Built a workflow** for complex deployments
- ✅ **Deployed a three-tier application** from scratch
- ✅ **Implemented CI/CD** with Jenkins or AWX
- ✅ **Managed secrets** with Ansible Vault
- ✅ **Understood** when to use AWX vs Jenkins vs CLI

**You're now ready to automate enterprise infrastructure with confidence!**

---

Happy Learning! 🚀🎉

## 🔥 Quick Start Commands

```bash
# Clone exercise repository
git clone https://github.com/YOUR_USERNAME/ansible-webapp-deployment.git
cd ansible-webapp-deployment

# Install dependencies
pip3 install openstacksdk
ansible-galaxy collection install openstack.cloud

# Configure OpenStack
cp clouds.yaml.example ~/.config/openstack/clouds.yaml
# Edit with your OpenStack details

# Test connection
openstack --os-cloud=myopenstack server list

# Deploy!
ansible-playbook playbooks/site.yml --vault-password-file=vault_password.txt
```

**Now access AWX at** `http://localhost:8080` **and create your first job template!**
