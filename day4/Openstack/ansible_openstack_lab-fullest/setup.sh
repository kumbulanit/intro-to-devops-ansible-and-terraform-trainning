#!/usr/bin/env bash

################################################################################
# OpenStack Ansible Lab - Interactive Setup Script
# Installs dependencies into a project-local virtual environment and prepares
# the lab for Ubuntu 22.04/24.04 hosts.
################################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_BIN=${PYTHON:-python3}
VENV_DIR=${VENV_DIR:-"${SCRIPT_DIR}/.venv"}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}OK${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}WARN${NC} $1"
}

print_error() {
    echo -e "${RED}ERR${NC} $1"
}

print_info() {
    echo -e "${BLUE}INFO${NC} $1"
}

check_root() {
    if [[ ${EUID} -eq 0 ]]; then
        print_warning "Running as root. A regular sudo-capable user is recommended."
        read -r -p "Continue anyway? (y/n) " reply
        if [[ ! ${reply} =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

check_python() {
    print_header "Checking Python Installation"

    if command -v "${PYTHON_BIN}" >/dev/null 2>&1; then
        PYTHON_VERSION=$("${PYTHON_BIN}" --version | awk '{print $2}')
        print_success "Python found: ${PYTHON_VERSION}"
    else
        print_error "Python 3 not found. Install Python 3.10+ first."
        exit 1
    fi
}

prepare_virtualenv() {
    print_header "Preparing Virtual Environment"

    if [[ ! -d "${VENV_DIR}" ]]; then
        print_info "Creating virtual environment at ${VENV_DIR}"
        if ! "${PYTHON_BIN}" -m venv "${VENV_DIR}" >/dev/null 2>&1; then
            print_error "Failed to create a virtual environment."
            print_info "On Ubuntu install the required package with: sudo apt-get install -y python3-venv"
            exit 1
        fi
    else
        print_success "Virtual environment already exists: ${VENV_DIR}"
    fi

    PYTHON_CMD="${VENV_DIR}/bin/python"
    PIP_CMD="${VENV_DIR}/bin/pip"
    ANSIBLE_CMD="${VENV_DIR}/bin/ansible"
    ANSIBLE_GALAXY_CMD="${VENV_DIR}/bin/ansible-galaxy"
    ANSIBLE_PLAYBOOK_CMD="${VENV_DIR}/bin/ansible-playbook"

    "${PYTHON_CMD}" -m pip install --quiet --upgrade pip
    print_success "pip is ready inside the virtual environment"
}

check_ansible() {
    print_header "Checking Ansible Installation"

    if [[ -x "${ANSIBLE_CMD}" ]]; then
        ANSIBLE_VERSION=$("${ANSIBLE_CMD}" --version | head -n1)
        print_success "Using ${ANSIBLE_VERSION}"
    else
        print_info "Ansible will be installed from requirements.txt"
    fi
}

install_python_deps() {
    print_header "Installing Python OpenStack Dependencies"

    if [[ -f "${SCRIPT_DIR}/requirements.txt" ]]; then
        print_info "Installing from ${SCRIPT_DIR}/requirements.txt"
        "${PIP_CMD}" install -r "${SCRIPT_DIR}/requirements.txt"
        print_success "Python dependencies installed"
    else
        print_error "requirements.txt not found in ${SCRIPT_DIR}"
        exit 1
    fi
}

install_ansible_collections() {
    print_header "Installing Ansible Collections"

    if [[ -f "${SCRIPT_DIR}/requirements.yml" ]]; then
        print_info "Installing from ${SCRIPT_DIR}/requirements.yml"
        "${ANSIBLE_GALAXY_CMD}" collection install -r "${SCRIPT_DIR}/requirements.yml" --force
        print_success "Ansible collections installed"
    else
        print_error "requirements.yml not found in ${SCRIPT_DIR}"
        exit 1
    fi
}

verify_openstack_sdk() {
    print_header "Verifying OpenStack SDK Installation"

    if "${PYTHON_CMD}" -c "import openstack" 2>/dev/null; then
        SDK_VERSION=$("${PYTHON_CMD}" -c "import openstack; print(openstack.version.__version__)")
        print_success "OpenStack SDK is working (version: ${SDK_VERSION})"
    else
        print_error "OpenStack SDK verification failed"
        exit 1
    fi
}

check_clouds_config() {
    local clouds_file="${SCRIPT_DIR}/clouds.yaml"

    print_header "Checking OpenStack Configuration"

    if [[ -f "${clouds_file}" ]]; then
        print_success "clouds.yaml found at ${clouds_file}"
        print_info "Update it with real credentials if you have not already."
        return
    fi

    print_warning "clouds.yaml not found. Creating a template at ${clouds_file}"
    cat > "${clouds_file}" <<'EOF'
# OpenStack Clouds Configuration
# Update with your OpenStack credentials

clouds:
  mycloud:
    auth:
      auth_url: https://your-openstack-endpoint:5000/v3
      username: your-username
      password: your-password
      project_name: your-project
      user_domain_name: Default
      project_domain_name: Default
    region_name: RegionOne
    interface: public
    identity_api_version: 3
EOF
    print_info "Template clouds.yaml created. You can also use ~/.config/openstack/clouds.yaml."
}

test_openstack_connection() {
    local test_playbook

    print_header "Testing OpenStack Connection (Optional)"

    read -r -p "Would you like to test the OpenStack connection now? (y/n) " reply
    if [[ ! ${reply} =~ ^[Yy]$ ]]; then
        return
    fi

    test_playbook="$(mktemp "${SCRIPT_DIR}/test-connection.XXXXXX.yml")"
    cat > "${test_playbook}" <<'EOF'
---
- name: Test OpenStack Connection
  hosts: localhost
  gather_facts: false
  tasks:
    - name: List available images
      openstack.cloud.image_info:
        cloud: mycloud
      register: images
      ignore_errors: true

    - name: Connection test result
      debug:
        msg: "{{ 'SUCCESS: Connected to OpenStack' if images is succeeded else 'FAILED: Could not connect' }}"
EOF

    if "${ANSIBLE_PLAYBOOK_CMD}" "${test_playbook}" 2>/dev/null; then
        print_success "OpenStack connection test passed"
    else
        print_warning "Connection test failed. Check clouds.yaml and your cloud reachability."
    fi

    rm -f "${test_playbook}"
}

display_summary() {
    print_header "Installation Summary"

    echo -e "${GREEN}All dependencies installed successfully.${NC}\n"
    echo "Environment:"
    echo "  Virtualenv: ${VENV_DIR}"
    echo "  Activate:   source \"${VENV_DIR}/bin/activate\""
    echo ""
    echo "Installed components:"
    echo "  - OpenStack SDK and CLI clients"
    echo "  - Ansible and the openstack.cloud collection"
    echo "  - Supporting Python packages from requirements.txt"
    echo ""
    echo "Next steps:"
    echo "  1. Update ${SCRIPT_DIR}/clouds.yaml or ~/.config/openstack/clouds.yaml"
    echo "  2. Test connection: ${ANSIBLE_PLAYBOOK_CMD} ${SCRIPT_DIR}/test-openstack.yml"
    echo "  3. Run scenarios: ${ANSIBLE_PLAYBOOK_CMD} ${SCRIPT_DIR}/scenario1_basic_vm.yml"
    echo ""
}

main() {
    clear || true
    print_header "OpenStack Ansible Lab Setup"
    echo "This script installs the lab dependencies into a project-local virtual environment."
    echo ""

    check_root
    check_python
    prepare_virtualenv
    check_ansible
    install_python_deps
    install_ansible_collections
    verify_openstack_sdk
    check_clouds_config
    test_openstack_connection
    display_summary

    print_success "Setup complete"
}

main "$@"
