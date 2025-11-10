# OpenStack VM Provisioning Role

![Ansible Role](https://img.shields.io/badge/ansible-role-blue.svg)
![OpenStack](https://img.shields.io/badge/cloud-openstack-red.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)

A comprehensive Ansible role for provisioning virtual machines on OpenStack cloud infrastructure. This role handles security group creation, VM provisioning, floating IP assignment, and dynamic inventory management.

## Features

- ✅ **Security Group Management** - Creates custom security groups with configurable rules
- ✅ **VM Provisioning** - Launches OpenStack instances with custom specifications
- ✅ **Floating IP Assignment** - Automatically assigns public IPs to VMs
- ✅ **Dynamic Inventory** - Adds provisioned VMs to Ansible inventory for subsequent plays
- ✅ **SSH Connectivity** - Waits for SSH to become available before continuing
- ✅ **Idempotent** - Safe to run multiple times without duplicating resources
- ✅ **Metadata Injection** - Supports custom VM metadata and user-data
- ✅ **State Management** - Saves VM information to files for reference

## Requirements

### Ansible Collections

```yaml
collections:
  - openstack.cloud
```

Install with:
```bash
ansible-galaxy collection install openstack.cloud
```

### Python Libraries

```bash
pip install openstacksdk
```

### OpenStack Configuration

A `clouds.yaml` file configured with your OpenStack credentials:

```yaml
clouds:
  mycloud:
    auth:
      auth_url: https://openstack.example.com:5000/v3
      username: your_username
      password: your_password
      project_name: your_project
      user_domain_name: Default
      project_domain_name: Default
    region_name: RegionOne
    interface: public
```

## Role Variables

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `os_cloud_name` | Name of cloud from clouds.yaml | `mycloud` |
| `os_vm_name` | Name for the VM | `web-server-01` |
| `os_image` | Image name or ID | `Ubuntu-22.04` |
| `os_flavor` | Flavor name or ID | `m1.medium` |
| `os_network` | Network name or ID | `private-network` |
| `os_key_name` | SSH key pair name | `my-keypair` |

### Optional Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `os_security_group` | `{{ os_vm_name }}-sg` | Security group name |
| `os_security_group_description` | `Security group for {{ os_vm_name }}` | Description |
| `os_assign_floating_ip` | `true` | Assign floating IP to VM |
| `os_floating_ip_pool` | `public` | Floating IP pool name |
| `os_auto_ip` | `false` | Auto-assign IP from pool |
| `os_wait_for_ssh` | `true` | Wait for SSH availability |
| `os_ssh_timeout` | `300` | SSH wait timeout (seconds) |
| `os_add_to_inventory` | `true` | Add VM to dynamic inventory |
| `os_inventory_group` | `openstack_servers` | Inventory group name |
| `os_save_vm_info` | `true` | Save VM info to file |
| `os_vm_info_file` | `/tmp/{{ os_vm_name }}_info.json` | VM info file path |
| `os_availability_zone` | (optional) | Availability zone |
| `os_boot_from_volume` | `false` | Boot from volume |
| `os_volume_size` | `20` | Root volume size (GB) |
| `os_metadata` | `{}` | Custom VM metadata |
| `os_userdata` | (optional) | Cloud-init user data |

### Security Rules

The `os_security_rules` variable defines firewall rules:

```yaml
os_security_rules:
  - protocol: tcp
    port_range_min: 22
    port_range_max: 22
    remote_ip_prefix: "0.0.0.0/0"
    description: "SSH access"
  - protocol: tcp
    port_range_min: 80
    port_range_max: 80
    remote_ip_prefix: "0.0.0.0/0"
    description: "HTTP access"
  - protocol: tcp
    port_range_min: 443
    port_range_max: 443
    remote_ip_prefix: "0.0.0.0/0"
    description: "HTTPS access"
  - protocol: icmp
    remote_ip_prefix: "0.0.0.0/0"
    description: "ICMP (ping)"
```

## Dependencies

None.

## Example Playbook

### Basic Usage

```yaml
---
- name: Provision OpenStack VM
  hosts: localhost
  gather_facts: false
  roles:
    - role: advanced/openstack-vm
      os_cloud_name: mycloud
      os_vm_name: web-server-01
      os_image: Ubuntu-22.04
      os_flavor: m1.medium
      os_network: private-network
      os_key_name: my-keypair
```

### Advanced Usage with Custom Security Rules

```yaml
---
- name: Provision Database Server
  hosts: localhost
  gather_facts: false
  vars:
    os_cloud_name: mycloud
    os_vm_name: db-server-01
    os_image: Ubuntu-22.04
    os_flavor: m1.large
    os_network: private-network
    os_key_name: my-keypair
    os_security_rules:
      - protocol: tcp
        port_range_min: 22
        port_range_max: 22
        remote_ip_prefix: "10.0.0.0/8"
        description: "SSH from internal network"
      - protocol: tcp
        port_range_min: 5432
        port_range_max: 5432
        remote_ip_prefix: "10.0.0.0/8"
        description: "PostgreSQL from internal network"
    os_metadata:
      role: database
      environment: production
      backup: daily
  roles:
    - advanced/openstack-vm
```

### Multi-VM Deployment

```yaml
---
- name: Provision Multiple VMs
  hosts: localhost
  gather_facts: false
  vars:
    os_cloud_name: mycloud
    os_image: Ubuntu-22.04
    os_flavor: m1.medium
    os_network: private-network
    os_key_name: my-keypair
    
    vm_definitions:
      - name: web-01
        group: webservers
      - name: web-02
        group: webservers
      - name: db-01
        group: databases
  
  tasks:
    - name: Provision VMs
      include_role:
        name: advanced/openstack-vm
      vars:
        os_vm_name: "{{ item.name }}"
        os_inventory_group: "{{ item.group }}"
      loop: "{{ vm_definitions }}"

- name: Configure Web Servers
  hosts: webservers
  become: true
  roles:
    - beginner/webserver

- name: Configure Database Servers
  hosts: databases
  become: true
  roles:
    - beginner/database
```

### Boot from Volume

```yaml
---
- name: Provision VM with Boot Volume
  hosts: localhost
  gather_facts: false
  roles:
    - role: advanced/openstack-vm
      os_cloud_name: mycloud
      os_vm_name: persistent-vm
      os_image: Ubuntu-22.04
      os_flavor: m1.medium
      os_network: private-network
      os_key_name: my-keypair
      os_boot_from_volume: true
      os_volume_size: 50
```

### With Cloud-Init User Data

```yaml
---
- name: Provision VM with Custom Configuration
  hosts: localhost
  gather_facts: false
  roles:
    - role: advanced/openstack-vm
      os_cloud_name: mycloud
      os_vm_name: configured-vm
      os_image: Ubuntu-22.04
      os_flavor: m1.medium
      os_network: private-network
      os_key_name: my-keypair
      os_userdata: |
        #cloud-config
        package_update: true
        package_upgrade: true
        packages:
          - docker.io
          - python3-pip
        runcmd:
          - systemctl enable docker
          - systemctl start docker
          - usermod -aG docker ubuntu
```

## Role Output

The role sets the following facts that can be used in subsequent tasks:

| Fact | Description |
|------|-------------|
| `vm_info` | Complete VM information from OpenStack |
| `vm_ip` | VM's floating IP (if assigned) |
| `vm_id` | VM's OpenStack UUID |
| `vm_name` | VM's name |

### Example Using Output

```yaml
- name: Provision VM
  include_role:
    name: advanced/openstack-vm
  vars:
    os_vm_name: test-vm

- name: Display VM Information
  debug:
    msg: |
      VM Name: {{ vm_name }}
      VM ID: {{ vm_id }}
      VM IP: {{ vm_ip }}
      Full Info: {{ vm_info }}

- name: Add VM to /etc/hosts
  lineinfile:
    path: /etc/hosts
    line: "{{ vm_ip }} {{ vm_name }}"
  delegate_to: localhost
```

## Testing

### Prerequisites

1. Configure `clouds.yaml` with valid credentials
2. Ensure you have available quota for VM, floating IP, and security groups
3. Verify network and image exist in your OpenStack project

### Test Playbook

```yaml
---
- name: Test OpenStack VM Role
  hosts: localhost
  gather_facts: false
  
  tasks:
    - name: Provision test VM
      include_role:
        name: advanced/openstack-vm
      vars:
        os_cloud_name: mycloud
        os_vm_name: test-vm-{{ ansible_date_time.epoch }}
        os_image: Ubuntu-22.04
        os_flavor: m1.small
        os_network: private-network
        os_key_name: my-keypair
    
    - name: Verify VM is accessible
      wait_for:
        host: "{{ vm_ip }}"
        port: 22
        timeout: 300
      delegate_to: localhost
    
    - name: Test SSH connection
      command: ssh -o StrictHostKeyChecking=no ubuntu@{{ vm_ip }} "echo 'VM is accessible'"
      changed_when: false
    
    - name: Cleanup - Delete test VM
      openstack.cloud.server:
        cloud: "{{ os_cloud_name }}"
        name: "{{ vm_name }}"
        state: absent
      when: cleanup | default(false)
```

Run with:
```bash
ansible-playbook test-openstack-vm.yml
```

## Troubleshooting

### Common Issues

**Problem**: `clouds.yaml not found`
```bash
# Solution: Set environment variable
export OS_CLIENT_CONFIG_FILE=/path/to/clouds.yaml
```

**Problem**: `Authentication failed`
```bash
# Verify credentials
openstack --os-cloud=mycloud server list
```

**Problem**: `Quota exceeded`
```bash
# Check quotas
openstack quota show
```

**Problem**: `Network not found`
```bash
# List available networks
openstack network list
```

**Problem**: `Image not found`
```bash
# List available images
openstack image list
```

**Problem**: `Floating IP pool exhausted`
```bash
# Check available floating IPs
openstack floating ip list
# Or disable floating IP assignment
os_assign_floating_ip: false
```

### Debug Mode

Enable verbose output:

```yaml
- name: Provision VM with debug
  include_role:
    name: advanced/openstack-vm
  vars:
    os_cloud_name: mycloud
    os_vm_name: debug-vm
    # ... other vars
  environment:
    OS_DEBUG: 1
```

## Performance Considerations

- **Parallel Provisioning**: Use `async` for multiple VMs
- **Image Caching**: Pre-download images to reduce provisioning time
- **Network Placement**: Use placement hints for optimal network performance
- **Volume Performance**: Use SSD-backed volumes for I/O intensive workloads

## Security Best Practices

1. **Restrict SSH Access**: Limit SSH to specific IP ranges
2. **Use Key-Based Auth**: Never use password authentication
3. **Minimal Security Rules**: Only open required ports
4. **Internal Networks**: Use private networks for inter-VM communication
5. **Rotate Keys**: Regularly rotate SSH keypairs
6. **Audit Logs**: Enable OpenStack audit logging
7. **Secrets Management**: Use Ansible Vault for sensitive variables

## License

MIT

## Author Information

Created for Day 5 - Ansible Roles and Galaxy Training

For issues and contributions, please refer to the lab documentation.
