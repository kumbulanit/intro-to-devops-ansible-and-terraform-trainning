# Webserver Role

A beginner-friendly Ansible role for installing and configuring Apache or Nginx web server.

## Requirements

- Ansible 2.9 or higher
- Target systems: Ubuntu 20.04+, Debian 10+, CentOS/RHEL 7+

## Role Variables

Available variables with their default values (see `defaults/main.yml`):

```yaml
# Web server type
webserver_type: apache

# Service configuration
webserver_service: apache2
webserver_user: www-data
webserver_group: www-data

# Paths
document_root: /var/www/html

# Website content
site_name: "My Ansible Managed Site"
site_tagline: "Deployed with Ansible Roles"
site_background_color: "#4a90e2"

# Features
configure_firewall: true
webserver_custom_config: false
enable_ssl: false

# Ports
webserver_http_port: 80
webserver_https_port: 443
```

## Dependencies

None.

## Example Playbook

Basic usage:

```yaml
---
- name: Deploy web server
  hosts: webservers
  become: true
  
  roles:
    - role: webserver
```

With custom variables:

```yaml
---
- name: Deploy custom web server
  hosts: webservers
  become: true
  
  roles:
    - role: webserver
      vars:
        site_name: "Production Website"
        site_tagline: "Powered by Ansible"
        site_background_color: "#2ecc71"
        enable_ssl: true
```

## Testing

Test the role locally:

```bash
# Create a test playbook
cat > test.yml <<EOF
---
- hosts: localhost
  become: true
  roles:
    - webserver
EOF

# Run the playbook
ansible-playbook test.yml
```

Verify the deployment:

```bash
# Check service status
sudo systemctl status apache2

# Test the web server
curl http://localhost
```

## License

MIT

## Author Information

Created for Ansible Training - Day 5: Roles and Galaxy
