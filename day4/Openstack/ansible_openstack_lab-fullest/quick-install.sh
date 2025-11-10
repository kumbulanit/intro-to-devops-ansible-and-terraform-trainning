#!/bin/bash

################################################################################
# Quick Install Script for OpenStack Ansible Dependencies
# A faster alternative to setup.sh for experienced users
################################################################################

set -e

echo "=================================="
echo "Quick OpenStack Ansible Setup"
echo "=================================="
echo ""

# Detect Python
if command -v python3 &> /dev/null; then
    PYTHON="python3"
    PIP="pip3"
else
    echo "Error: Python 3 not found"
    exit 1
fi

echo "→ Installing Python packages..."
$PIP install --user -q -r requirements.txt

echo "→ Installing Ansible collections..."
ansible-galaxy collection install -r requirements.yml --force > /dev/null 2>&1

echo "→ Verifying installation..."
if $PYTHON -c "import openstack" 2>/dev/null; then
    VERSION=$($PYTHON -c "import openstack; print(openstack.version.__version__)")
    echo "✓ OpenStack SDK installed (v$VERSION)"
else
    echo "✗ OpenStack SDK installation failed"
    exit 1
fi

if ansible-galaxy collection list | grep -q openstack.cloud; then
    echo "✓ Ansible OpenStack collection installed"
else
    echo "✗ Ansible collection installation failed"
    exit 1
fi

echo ""
echo "✓ Installation complete!"
echo ""
echo "Next steps:"
echo "  1. Update clouds.yaml with your OpenStack credentials"
echo "  2. Test: ansible-playbook test-openstack.yml"
echo "  3. Run scenarios: ansible-playbook scenario1_basic_vm.yml"
echo ""
