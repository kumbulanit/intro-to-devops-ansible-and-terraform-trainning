# Ansible OpenStack Lab Kit - Complete Edition

This comprehensive lab kit is designed for hands-on training with Ansible automation of OpenStack resources. It includes complete infrastructure provisioning, advanced scenarios, and production-ready patterns.

## 📦 Contents

- **16 Complete Scenarios** - From basic VMs to complex multi-tier deployments
- **Full Infrastructure Support** - Networks, volumes, security groups, keypairs
- **Teardown Playbooks** - Clean resource removal for all scenarios
- **Installation Tools** - Automated setup scripts and dependency management
- **Testing Suite** - Connection and module verification
- **Documentation** - Detailed guides and inline comments

### Files Included

- 16 Ansible playbooks (`scenario1` to `scenario16`)
- 16 Teardown playbooks (complete resource cleanup)
- `inventory.ini` - Ansible inventory configuration
- `clouds.yaml` - OpenStack authentication template
- `requirements.txt` - Python dependencies
- `requirements.yml` - Ansible collections
- `setup.sh` - Interactive installation script
- `quick-install.sh` - Fast automated setup
- `test-openstack.yml` - Connection and module testing
- `lab_guide.md` - Comprehensive lab guide
- `INSTALLATION.md` - Detailed installation instructions

## 🚀 Quick Start

### Option 1: Automated Installation (Recommended)

```bash
# Navigate to lab directory
cd day4/Openstack/ansible_openstack_lab-fullest/

# Run quick install
./quick-install.sh

# Configure OpenStack credentials
# Edit clouds.yaml with your OpenStack details

# Test connection
ansible-playbook test-openstack.yml

# Run first scenario
ansible-playbook scenario1_basic_vm.yml
```

### Option 2: Manual Installation

```bash
# Install Python dependencies
pip3 install --user -r requirements.txt

# Install Ansible collections
ansible-galaxy collection install -r requirements.yml

# Configure clouds.yaml (see below)

# Test and run
ansible-playbook test-openstack.yml
ansible-playbook scenario1_basic_vm.yml
```

## ⚙️ Prerequisites

### System Requirements

- Python 3.8 or higher
- Ansible 2.9 or higher
- Access to OpenStack cloud (DevStack, production, or hosted)
- SSH key pair (generated with `ssh-keygen` if needed)

### OpenStack Requirements

- Valid OpenStack credentials
- Access to:
  - Compute service (Nova)
  - Network service (Neutron)
  - Image service (Glance)
  - Block Storage service (Cinder)
  - Identity service (Keystone)
- At least one available:
  - Ubuntu/Debian/CentOS image
  - Flavor (m1.small or larger)
  - External network (for floating IPs)

### Python Packages (Installed Automatically)

- `openstacksdk` - Core OpenStack SDK
- `python-openstackclient` - CLI tools
- `python-novaclient` - Compute API
- `python-neutronclient` - Networking API
- `python-cinderclient` - Block Storage API
- `python-glanceclient` - Image API
- `python-keystoneclient` - Identity API

### Ansible Collections (Installed Automatically)

- `openstack.cloud` - OpenStack modules
- `community.general` - General utilities
- `ansible.posix` - POSIX utilities

## 🔐 Configuration

### OpenStack Authentication

Create or edit `clouds.yaml` in the lab directory:

```yaml
clouds:
  mycloud:
    auth:
      auth_url: https://your-openstack:5000/v3
      username: your-username
      password: your-password
      project_name: your-project
      user_domain_name: Default
      project_domain_name: Default
    region_name: RegionOne
    interface: public
    identity_api_version: 3
```

**For DevStack:**
```yaml
clouds:
  devstack:
    region_name: RegionOne
    auth:
      auth_url: http://127.0.0.1/identity
      username: demo
      password: secret
      project_name: demo
      user_domain_name: Default
      project_domain_name: Default
    interface: public
    identity_api_version: 3
```


## ▶️ Running Scenarios

### Basic Scenario Execution

```bash
# Run a scenario
ansible-playbook scenario1_basic_vm.yml

# With verbose output
ansible-playbook scenario1_basic_vm.yml -v

# With extra verbosity (debug)
ansible-playbook scenario1_basic_vm.yml -vvv
```

### Scenarios Using Ansible Vault

```bash
# Scenario 13 uses encrypted variables
ansible-playbook scenario13_vaulted_vars.yml --ask-vault-pass

# With vault password file
ansible-playbook scenario13_vaulted_vars.yml --vault-password-file=.vault_pass
```

### Check Mode (Dry Run)

```bash
# See what would be created without actually creating
ansible-playbook scenario1_basic_vm.yml --check
```

## 📋 Available Scenarios

| Scenario | Description | Key Features |
|----------|-------------|--------------|
| 1 | Basic VM | Simple VM provisioning with keypair and security group |
| 2 | Network & Subnet | Create custom networks and subnets |
| 3 | Router & Gateway | Set up routing and external network access |
| 4 | Floating IP | Assign public IPs to instances |
| 5 | Security Groups | Advanced security group rules |
| 6 | Multiple VMs | Launch multiple instances with loop |
| 7 | Volume Attachment | Create and attach block storage |
| 8 | Complex Network | Multi-tier network topology |
| 9 | Load Balancer | Set up load balancing (LBaaS) |
| 10 | Auto-scaling | Dynamic scaling based on metrics |
| 11 | User Data | Cloud-init and instance customization |
| 12 | LAMP Stack | Full web application stack |
| 13 | Ansible Vault | Encrypted sensitive data |
| 14 | HAProxy LB | High-availability load balancer |
| 15 | Molecule Testing | Role testing framework |
| 16 | Complete Stack | Full production-ready deployment |

## 🧹 Cleanup and Teardown

### Clean Up Individual Scenarios

Each scenario has a matching teardown playbook:

```bash
# Clean up scenario 1
ansible-playbook teardown_scenario1.yml

# Clean up scenario 4
ansible-playbook teardown_scenario4.yml
```

### Complete Cleanup

```bash
# Run teardown for all resources
for i in {1..16}; do
  ansible-playbook teardown_scenario${i}.yml 2>/dev/null || true
done
```

### Manual Cleanup (if needed)

```bash
# List and delete resources manually
openstack server list --os-cloud=mycloud
openstack server delete <server-name>

openstack volume list --os-cloud=mycloud
openstack volume delete <volume-name>
```

## 🧪 Testing

### Test OpenStack Connection

```bash
# Run comprehensive test suite
ansible-playbook test-openstack.yml
```

This tests:
- Authentication
- Image service
- Network service  
- Compute service
- Volume service
- Security groups
- Keypairs

### Test with OpenStack CLI

```bash
# Test authentication
openstack --os-cloud=mycloud token issue

# List resources
openstack image list --os-cloud=mycloud
openstack network list --os-cloud=mycloud
openstack flavor list --os-cloud=mycloud
openstack server list --os-cloud=mycloud
```

## 🔧 Troubleshooting

### Common Issues

**Issue: "No module named 'openstack'"**
```bash
pip3 install --user openstacksdk
```

**Issue: "Collection openstack.cloud not found"**
```bash
ansible-galaxy collection install openstack.cloud --force
```

**Issue: Authentication failures**
```bash
# Verify credentials
openstack --os-cloud=mycloud image list

# Check clouds.yaml location and format
cat clouds.yaml
```

**Issue: "Image not found"**
```bash
# List available images
openstack image list --os-cloud=mycloud

# Update playbook with correct image name
```

**Issue: "No valid host was found"**
```bash
# Check available flavors
openstack flavor list --os-cloud=mycloud

# Update playbook with correct flavor name
```

### Getting Help

1. **Run with verbose output**: `ansible-playbook scenario1_basic_vm.yml -vvv`
2. **Check test suite**: `ansible-playbook test-openstack.yml`
3. **Verify CLI access**: `openstack image list --os-cloud=mycloud`
4. **Review logs**: Check `/var/log/ansible.log` if configured
5. **Check documentation**: See `INSTALLATION.md` and `lab_guide.md`

## 📚 Learning Path

### Beginner (Start Here)

1. **Scenario 1** - Basic VM provisioning
2. **Scenario 2** - Network creation
3. **Scenario 3** - Router and gateway setup
4. **Scenario 4** - Floating IP assignment

### Intermediate

5. **Scenario 5** - Security group management
6. **Scenario 6** - Multiple VM deployment
7. **Scenario 7** - Volume management
8. **Scenario 8** - Complex networking

### Advanced

9. **Scenario 12** - LAMP stack deployment
10. **Scenario 14** - HAProxy load balancer
11. **Scenario 16** - Complete production stack
12. **Scenario 15** - Testing with Molecule

### Expert

13. **Scenario 13** - Ansible Vault integration
14. **Scenario 9** - Load balancer (LBaaS)
15. **Scenario 10** - Auto-scaling setup

## 💡 Tips and Best Practices

### Resource Naming

All scenarios use consistent naming:
- **Prefix**: `lab-` or `ansible-`
- **Purpose**: Descriptive names
- **Cleanup**: Easy identification for teardown

### Idempotency

All playbooks are idempotent:
- Safe to run multiple times
- Only creates missing resources
- Updates existing resources if needed

### Variables

Customize scenarios by modifying variables:
```yaml
vars:
  vm_name: "my-custom-vm"
  flavor_name: "m1.large"
  image_name: "ubuntu-22.04"
```

### Tags

Run specific parts of playbooks:
```bash
# Only create network
ansible-playbook scenario2_network_subnet.yml --tags network

# Skip security group creation
ansible-playbook scenario1_basic_vm.yml --skip-tags security
```

## 📖 Additional Resources

- **Installation Guide**: `INSTALLATION.md` - Complete setup instructions
- **Lab Guide**: `lab_guide.md` - Detailed scenario walkthroughs
- **OpenStack Docs**: https://docs.openstack.org/
- **Ansible OpenStack**: https://docs.ansible.com/ansible/latest/collections/openstack/cloud/
- **OpenStack SDK**: https://docs.openstack.org/openstacksdk/

## 🤝 Contributing

Found an issue or have suggestions?
- Review scenario playbooks for inline comments
- Check teardown playbooks for resource cleanup
- Test in your environment and provide feedback

## 📝 Notes

- All scenarios create resources in your OpenStack project
- Resources consume quota (compute, network, storage)
- Always run teardown playbooks to clean up
- Monitor resource usage with `openstack quota show`
- Keep clouds.yaml secure (contains credentials)

## ✅ Verification Checklist

Before starting scenarios:

- [ ] Python 3.8+ installed
- [ ] All Python packages installed (`pip3 list | grep openstack`)
- [ ] Ansible collections installed (`ansible-galaxy collection list`)
- [ ] clouds.yaml configured with valid credentials
- [ ] Test suite passes (`ansible-playbook test-openstack.yml`)
- [ ] Can list images (`openstack image list --os-cloud=mycloud`)
- [ ] SSH keypair available (`ls ~/.ssh/id_rsa.pub`)

---

**Ready to start?** Run `./quick-install.sh` then `ansible-playbook test-openstack.yml` 🚀
