# Nginx Tested Role

[![Molecule Test](https://img.shields.io/badge/molecule-tested-brightgreen.svg)](https://molecule.readthedocs.io/)
[![Ansible Galaxy](https://img.shields.io/badge/galaxy-nginx__tested-blue.svg)](https://galaxy.ansible.com/)

A production-ready Nginx role with comprehensive Molecule tests for automated validation.

## Features

- ✅ Fully tested with Molecule
- ✅ Idempotent tasks
- ✅ CI/CD ready
- ✅ Health check endpoint
- ✅ Security headers configured
- ✅ Cross-platform support (Ubuntu, Debian)

## Requirements

- Ansible >= 2.10
- Python >= 3.6
- For testing: Molecule, Docker

## Role Variables

See `defaults/main.yml` for all available variables:

```yaml
nginx_document_root: /var/www/html
nginx_listen_port: 80
nginx_server_name: localhost
site_title: "Nginx Tested Role"
site_description: "Deployed and tested with Molecule"
```

## Dependencies

None.

## Example Playbook

```yaml
---
- hosts: webservers
  become: true
  roles:
    - role: nginx-tested
      vars:
        site_title: "My Production Site"
        site_description: "Reliably deployed with Ansible"
```

## Testing

This role includes comprehensive Molecule tests.

### Run tests locally:

```bash
# Install dependencies
pip install molecule[docker] ansible-lint yamllint

# Run full test suite
cd roles/nginx-tested
molecule test

# Or test individual steps
molecule create    # Create test container
molecule converge  # Apply the role
molecule verify    # Run tests
molecule destroy   # Clean up
```

### Test scenarios covered:

- ✅ Nginx installation
- ✅ Service status (running and enabled)
- ✅ Document root creation
- ✅ Content deployment
- ✅ HTTP response (port 80)
- ✅ Health endpoint
- ✅ Configuration validity
- ✅ Idempotence

## CI/CD Integration

This role is CI/CD ready. Example GitHub Actions workflow:

```yaml
name: Molecule Test
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Set up Python
        uses: actions/setup-python@v2
        with:
          python-version: '3.x'
      - name: Install dependencies
        run: |
          pip install molecule[docker] ansible-lint yamllint
      - name: Run Molecule tests
        run: |
          cd roles/nginx-tested
          molecule test
```

## Publishing to Galaxy

```bash
# Login to Galaxy
ansible-galaxy login

# Build and publish
ansible-galaxy role import <github-user> <repo-name>
```

## License

MIT

## Author Information

Created for Ansible Training - Day 5: Intermediate Roles with Molecule Testing

## Changelog

### v1.0.0 (Initial Release)
- Basic Nginx installation
- Health check endpoint
- Comprehensive Molecule tests
- Security headers
- Cross-platform support
