#!/bin/bash

################################################################################
# OpenStack Ansible Lab - Complete Setup Script
# This script installs all necessary dependencies for OpenStack Ansible modules
################################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Check if running as root
check_root() {
    if [ "$EUID" -eq 0 ]; then
        print_warning "Running as root. This is not recommended for pip installations."
        print_info "Consider running as regular user with sudo access."
        read -p "Continue anyway? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Check Python version
check_python() {
    print_header "Checking Python Installation"
    
    if command -v python3 &> /dev/null; then
        PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
        print_success "Python 3 found: $PYTHON_VERSION"
        PYTHON_CMD="python3"
        PIP_CMD="pip3"
    else
        print_error "Python 3 not found. Please install Python 3.8 or higher."
        exit 1
    fi
    
    # Check pip
    if ! command -v $PIP_CMD &> /dev/null; then
        print_warning "pip3 not found. Installing pip..."
        curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
        $PYTHON_CMD get-pip.py --user
        rm get-pip.py
        print_success "pip installed"
    else
        print_success "pip found"
    fi
}

# Check Ansible installation
check_ansible() {
    print_header "Checking Ansible Installation"
    
    if command -v ansible &> /dev/null; then
        ANSIBLE_VERSION=$(ansible --version | head -n1 | cut -d' ' -f2 | cut -d']' -f1 | cut -d'[' -f2)
        print_success "Ansible found: $ANSIBLE_VERSION"
    else
        print_warning "Ansible not found. Installing..."
        $PIP_CMD install --user ansible
        print_success "Ansible installed"
    fi
}

# Install Python OpenStack dependencies
install_python_deps() {
    print_header "Installing Python OpenStack Dependencies"
    
    if [ -f "requirements.txt" ]; then
        print_info "Installing from requirements.txt..."
        $PIP_CMD install --user -r requirements.txt
        print_success "Python dependencies installed"
    else
        print_error "requirements.txt not found!"
        exit 1
    fi
}

# Install Ansible collections
install_ansible_collections() {
    print_header "Installing Ansible Collections"
    
    if [ -f "requirements.yml" ]; then
        print_info "Installing Ansible collections..."
        ansible-galaxy collection install -r requirements.yml --force
        print_success "Ansible collections installed"
    else
        print_error "requirements.yml not found!"
        exit 1
    fi
}

# Verify OpenStack SDK
verify_openstack_sdk() {
    print_header "Verifying OpenStack SDK Installation"
    
    if $PYTHON_CMD -c "import openstack" 2>/dev/null; then
        SDK_VERSION=$($PYTHON_CMD -c "import openstack; print(openstack.version.__version__)")
        print_success "OpenStack SDK is working (version: $SDK_VERSION)"
    else
        print_error "OpenStack SDK verification failed!"
        exit 1
    fi
}

# Check clouds.yaml
check_clouds_config() {
    print_header "Checking OpenStack Configuration"
    
    if [ -f "clouds.yaml" ]; then
        print_success "clouds.yaml found"
        print_info "Please ensure your OpenStack credentials are configured in clouds.yaml"
    else
        print_warning "clouds.yaml not found!"
        print_info "Creating template clouds.yaml..."
        cat > clouds.yaml << 'EOF'
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
        print_info "Template clouds.yaml created. Please update with your credentials."
    fi
}

# Test OpenStack connection
test_openstack_connection() {
    print_header "Testing OpenStack Connection (Optional)"
    
    read -p "Would you like to test OpenStack connection? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Testing connection..."
        
        # Create test playbook
        cat > test-connection.yml << 'EOF'
---
- name: Test OpenStack Connection
  hosts: localhost
  gather_facts: no
  tasks:
    - name: List available images
      openstack.cloud.image_info:
        cloud: mycloud
      register: images
      ignore_errors: yes
    
    - name: Connection test result
      debug:
        msg: "{{ 'SUCCESS: Connected to OpenStack' if images is succeeded else 'FAILED: Could not connect' }}"
EOF
        
        if ansible-playbook test-connection.yml 2>/dev/null; then
            print_success "OpenStack connection test passed!"
        else
            print_warning "OpenStack connection test failed. Please check your clouds.yaml configuration."
        fi
        
        rm -f test-connection.yml
    fi
}

# Display summary
display_summary() {
    print_header "Installation Summary"
    
    echo -e "${GREEN}All dependencies installed successfully!${NC}\n"
    
    echo "Installed components:"
    echo "  • Python OpenStack SDK"
    echo "  • OpenStack CLI clients"
    echo "  • Ansible OpenStack collection (openstack.cloud)"
    echo "  • Supporting Ansible collections"
    echo ""
    
    echo "Next steps:"
    echo "  1. Update clouds.yaml with your OpenStack credentials"
    echo "  2. Test connection: ansible-playbook test-openstack.yml"
    echo "  3. Run scenarios: ansible-playbook scenario1_basic_vm.yml"
    echo ""
    
    echo "Useful commands:"
    echo "  • List collections: ansible-galaxy collection list"
    echo "  • Test OpenStack CLI: openstack image list"
    echo "  • Verify SDK: python3 -c 'import openstack; print(openstack.version.__version__)'"
    echo ""
}

# Main installation process
main() {
    clear
    print_header "OpenStack Ansible Lab Setup"
    echo "This script will install all necessary dependencies for OpenStack automation with Ansible."
    echo ""
    
    # Run checks and installations
    check_root
    check_python
    check_ansible
    install_python_deps
    install_ansible_collections
    verify_openstack_sdk
    check_clouds_config
    test_openstack_connection
    display_summary
    
    print_success "Setup complete! You're ready to use OpenStack with Ansible."
}

# Run main function
main
