# OpenStack Ansible Installation Guide

This guide provides complete instructions for setting up all OpenStack modules and dependencies needed for the lab scenarios.

## 📋 Prerequisites

- Python 3.8 or higher
- pip (Python package manager)
- Ansible 2.9 or higher
- Access to an OpenStack cloud environment
- OpenStack credentials (auth_url, username, password, project)

## 🚀 Quick Installation (Recommended)

For a fast, automated setup:

```bash
# Navigate to the lab directory
cd day4/Openstack/ansible_openstack_lab-fullest/

# Run quick install script
./quick-install.sh
```

This will:
- Create a project-local virtual environment in `.venv`
- Install all Python OpenStack packages
- Install Ansible collections
- Verify the installation

## 📦 Manual Installation

If you prefer step-by-step installation:

### Step 1: Install Python Dependencies

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
```

This installs:
- **openstacksdk** - Core OpenStack SDK
- **python-openstackclient** - CLI tools
- **python-novaclient** - Compute API
- **python-neutronclient** - Networking API
- **python-cinderclient** - Block Storage API
- **python-glanceclient** - Image API
- **python-keystoneclient** - Identity API

### Step 2: Install Ansible Collections

```bash
ansible-galaxy collection install -r requirements.yml
```

This installs:
- **openstack.cloud** - OpenStack modules
- **community.general** - General utilities
- **ansible.posix** - POSIX utilities

### Step 3: Verify Installation

```bash
# Check OpenStack SDK
python -c "import openstack; print('SDK version:', openstack.version.__version__)"

# Check Ansible collections
ansible-galaxy collection list | grep openstack

# Check OpenStack CLI
openstack --version
```

## ⚙️ Configuration

### Configure OpenStack Credentials

Edit `clouds.yaml` with your OpenStack credentials:

## Configuration

### clouds.yaml Setup

Create or edit `~/.config/openstack/clouds.yaml` (or `./clouds.yaml` in the project directory):

```yaml
clouds:
  mycloud:
    region_name: RegionOne
    auth:
      auth_url: http://10.0.3.15/identity
      username: demo
      password: secret
      project_name: demo
      user_domain_name: Default
      project_domain_name: Default
    interface: public
    identity_api_version: 3
  
  devstack:
    region_name: RegionOne
    auth:
      auth_url: http://10.0.3.15/identity
      username: demo
      password: secret
      project_name: demo
      user_domain_name: Default
      project_domain_name: Default
    interface: public
    identity_api_version: 3
```

**Important:** Replace `10.0.3.15` with your OpenStack endpoint IP address if different. The default configuration assumes OpenStack is running at `10.0.3.15`.

### Environment Variables (Alternative)

You can also use environment variables:

```bash
export OS_AUTH_URL=https://your-openstack:5000/v3
export OS_USERNAME=your-username
export OS_PASSWORD=your-password
export OS_PROJECT_NAME=your-project
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
```

## 🧪 Testing

### Test OpenStack Connection

```bash
.venv/bin/ansible-playbook test-openstack.yml
```

This comprehensive test checks:
- ✓ Authentication
- ✓ Image service (Glance)
- ✓ Network service (Neutron)
- ✓ Compute service (Nova)
- ✓ Volume service (Cinder)
- ✓ Security groups
- ✓ Keypairs

### Test CLI Connection

```bash
openstack image list
openstack network list
openstack flavor list
```

## 📚 Complete Installation (Full Script)

For detailed installation with prompts and validation:

```bash
./setup.sh
```

This interactive script:
1. Checks Python and pip
2. Checks Ansible
3. Installs Python dependencies
4. Installs Ansible collections
5. Verifies OpenStack SDK
6. Checks clouds.yaml configuration
7. Optionally tests OpenStack connection
8. Provides detailed summary, including the virtualenv activation command

## 🔧 Troubleshooting

### Issue: "No module named 'openstack'"

**Solution:**
```bash
source .venv/bin/activate
python -m pip install openstacksdk
```

### Issue: "Collection openstack.cloud not found"

**Solution:**
```bash
ansible-galaxy collection install openstack.cloud --force
```

### Issue: Authentication failures

**Solutions:**
1. Verify clouds.yaml credentials
2. Check OpenStack endpoint is accessible
3. Verify project/tenant name
4. Check user permissions

```bash
# Test with CLI
openstack --os-cloud=mycloud image list
```

### Issue: SSL certificate errors

**Solution:** Add to clouds.yaml:
```yaml
clouds:
  mycloud:
    verify: false  # For self-signed certificates
    # ... other settings
```

### Issue: Ubuntu blocks direct pip installs (PEP 668)

**Solution:**
```bash
sudo apt-get install -y python3-venv
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements.txt
```

## 📦 What Gets Installed

### Python Packages

| Package | Purpose |
|---------|---------|
| openstacksdk | Core OpenStack API library |
| python-openstackclient | Unified CLI client |
| python-novaclient | Compute (VM) management |
| python-neutronclient | Network management |
| python-cinderclient | Volume management |
| python-glanceclient | Image management |
| python-keystoneclient | Authentication |

### Ansible Collections

| Collection | Purpose |
|------------|---------|
| openstack.cloud | OpenStack modules for Ansible |
| community.general | General-purpose modules |
| ansible.posix | POSIX system modules |

## ✅ Verification Checklist

After installation, verify:

- [ ] Python 3.8+ installed
- [ ] pip installed and working
- [ ] Ansible 2.9+ installed
- [ ] openstacksdk installed
- [ ] OpenStack CLI clients installed
- [ ] openstack.cloud collection installed
- [ ] clouds.yaml configured
- [ ] test-openstack.yml passes

## 🎯 Next Steps

Once installation is complete:

1. **Review scenarios**: Check `lab_guide.md` for available scenarios
2. **Start with basics**: Run `scenario1_basic_vm.yml`
3. **Explore features**: Try different scenarios progressively
4. **Check documentation**: Each scenario has detailed comments

## 📖 Additional Resources

- [OpenStack SDK Documentation](https://docs.openstack.org/openstacksdk/)
- [Ansible OpenStack Collection](https://docs.ansible.com/ansible/latest/collections/openstack/cloud/)
- [OpenStack CLI Guide](https://docs.openstack.org/python-openstackclient/)

## 🆘 Getting Help

If you encounter issues:

1. Run diagnostic: `./setup.sh`
2. Check test: `ansible-playbook test-openstack.yml`
3. Verify CLI: `openstack image list --os-cloud=mycloud`
4. Check logs: `ansible-playbook scenario1_basic_vm.yml -vvv`

## 🔄 Updating Dependencies

To update to latest versions:

```bash
# Update Python packages
pip3 install --user --upgrade openstacksdk python-openstackclient

# Update Ansible collections
ansible-galaxy collection install openstack.cloud --force --upgrade
```

## 🧹 Uninstallation

To remove installed packages:

```bash
# Remove Python packages
pip3 uninstall openstacksdk python-openstackclient -y

# Remove Ansible collection
rm -rf ~/.ansible/collections/ansible_collections/openstack/cloud
```

---

**Installation complete!** You're ready to start working with OpenStack and Ansible. 🚀
