# Day 5: Ansible Roles and Galaxy - Playbooks

This directory contains progressively complex playbooks demonstrating Ansible roles usage from beginner to advanced levels.

## Playbook Overview

### Beginner Level

**01-webserver-basic.yml**
- Basic web server deployment using the `beginner/webserver` role
- Single role usage
- Simple variable configuration
- ✅ Topics: Role basics, default variables, templates

**02-database-basic.yml**
- PostgreSQL database deployment with `beginner/database` role
- Database creation and user management
- Post-deployment verification
- ✅ Topics: Handlers, service management, verification tasks

**03-complete-stack.yml**
- Multi-tier deployment with database and web server
- Multiple role orchestration
- Inter-server configuration
- ✅ Topics: Multi-role playbooks, role coordination, inventory groups

### Intermediate Level

**04-nginx-molecule-tested.yml**
- Deploys the `intermediate/nginx-tested` role
- Pre-flight checks and post-deployment verification
- Demonstrates using Molecule-tested roles
- ✅ Topics: Tested roles, health checks, comprehensive verification

**05-openstack-complete-stack.yml** (221 lines)
- Complete OpenStack infrastructure provisioning
- VM creation with security groups
- Dynamic inventory management
- Full stack deployment (DB + Web + App)
- ✅ Topics: Cloud provisioning, dynamic inventory, multi-play orchestration

### Advanced Level

**06-haproxy-loadbalancer.yml**
- HAProxy load balancer deployment
- Multiple backend server configuration
- Health monitoring and statistics
- ✅ Topics: Load balancing, high availability, monitoring

**07-complete-ha-stack.yml**
- High Availability infrastructure deployment
- OpenStack VM provisioning (LB + Web + DB)
- Complete stack integration
- Load balancer configuration with multiple backends
- ✅ Topics: HA architecture, full infrastructure orchestration, end-to-end deployment

**08-fullstack-with-dependencies.yml**
- Demonstrates role dependencies
- Uses `advanced/fullstack-app` which depends on database and webserver roles
- Automatic dependency resolution
- ✅ Topics: Role dependencies, meta/main.yml, dependency chains

## Usage Examples

### Basic Web Server Deployment
```bash
ansible-playbook -i inventory.ini playbooks/01-webserver-basic.yml
```

### Complete Stack with Database
```bash
ansible-playbook -i inventory.ini playbooks/03-complete-stack.yml \
  --extra-vars "db_password=SecurePass123"
```

### OpenStack Infrastructure (Requires clouds.yaml)
```bash
export OS_CLIENT_CONFIG_FILE=/path/to/clouds.yaml
ansible-playbook playbooks/05-openstack-complete-stack.yml \
  --extra-vars "os_cloud_name=mycloud"
```

### High Availability Stack
```bash
ansible-playbook playbooks/07-complete-ha-stack.yml
```

### Full Stack with Dependencies
```bash
ansible-playbook -i inventory.ini playbooks/08-fullstack-with-dependencies.yml
```

## Inventory Template

Use the provided `inventory.ini` as a template:

```ini
[webservers]
web01 ansible_host=192.168.1.10
web02 ansible_host=192.168.1.11

[databases]
db01 ansible_host=192.168.1.20

[loadbalancers]
lb01 ansible_host=192.168.1.30

[appservers]
app01 ansible_host=192.168.1.40

[all:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=~/.ssh/id_rsa
```

## Variable Overrides

All playbooks support variable overrides via command line:

```bash
ansible-playbook playbook.yml \
  --extra-vars "server_name=myserver.example.com" \
  --extra-vars "enable_ssl=true"
```

## Ansible Vault Integration

For production deployments, use Ansible Vault for sensitive data:

```bash
# Create vault file
ansible-vault create vault.yml

# Add sensitive variables
vault_db_password: SecurePassword123
vault_haproxy_password: AdminPass456
vault_app_password: AppSecret789

# Run playbook with vault
ansible-playbook playbook.yml --ask-vault-pass
```

## Pre-requisites

### For Local VMs
- Ansible 2.10+
- SSH access to target servers
- Python 3.6+ on target servers

### For OpenStack Deployments
- OpenStack cloud account
- Configured `clouds.yaml`
- `openstack.cloud` collection:
  ```bash
  ansible-galaxy collection install openstack.cloud
  ```
- Python `openstacksdk`:
  ```bash
  pip install openstacksdk
  ```

### For Molecule-tested Roles
- Docker (for running tests)
- Molecule:
  ```bash
  pip install molecule[docker]
  ```

## Testing Playbooks

Use the provided test script:

```bash
# Test syntax
./test-roles.sh syntax

# Test all playbooks
./test-roles.sh all
```

## Troubleshooting

### Connection Issues
```bash
# Test connectivity
ansible all -i inventory.ini -m ping

# Verbose output
ansible-playbook playbook.yml -vvv
```

### OpenStack Issues
```bash
# Verify OpenStack credentials
openstack --os-cloud=mycloud server list

# Check quotas
openstack quota show
```

### Role Issues
```bash
# List installed roles
ansible-galaxy role list

# Install required roles
ansible-galaxy install -r requirements.yml
```

## Playbook Progression

The playbooks are designed to build on each other:

1. **01-02**: Single role usage (webserver, database)
2. **03**: Multiple roles in one playbook
3. **04**: Using Molecule-tested roles
4. **05**: Cloud infrastructure provisioning
5. **06**: Advanced load balancer configuration
6. **07**: Complete HA infrastructure
7. **08**: Role dependencies demonstration

## Learning Path

### Week 1: Basics
- Run playbooks 01-03
- Understand role structure
- Modify default variables
- Create custom inventory

### Week 2: Intermediate
- Deploy playbook 04 with Molecule tests
- Experiment with OpenStack (05)
- Learn dynamic inventory

### Week 3: Advanced
- Deploy HA infrastructure (06-07)
- Understand role dependencies (08)
- Create custom roles
- Implement CI/CD with GitHub Actions

## Best Practices Demonstrated

✅ **Pre-tasks**: System updates, validation
✅ **Post-tasks**: Verification, health checks
✅ **Idempotency**: Safe to run multiple times
✅ **Error Handling**: Proper error checking
✅ **Documentation**: Inline comments
✅ **Variables**: Externalized configuration
✅ **Security**: Vault integration
✅ **Testing**: Molecule integration
✅ **Modularity**: Role composition

## Additional Resources

- [Ansible Documentation](https://docs.ansible.com)
- [Ansible Galaxy](https://galaxy.ansible.com)
- [OpenStack Collection Docs](https://docs.ansible.com/ansible/latest/collections/openstack/cloud/)
- [Molecule Documentation](https://molecule.readthedocs.io)

## Support

For issues or questions:
1. Check the role README files
2. Review lab documentation in parent directories
3. Run playbooks with `-vvv` for detailed output
4. Test individual tasks with `--tags` or `--start-at-task`

---

**Generated for**: Day 5 - Ansible Roles and Galaxy Training
**Last Updated**: 2024
