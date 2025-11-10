#!/bin/bash
# Grant Admin Permissions to Demo User for Training Purposes
# Run this script on your OpenStack controller node

echo "╔════════════════════════════════════════════════════════════╗"
echo "║   Grant Admin Permissions to Demo User (Training Only)    ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "⚠️  WARNING: This grants full admin permissions to demo user."
echo "    This is ONLY for training/demo purposes!"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Source OpenStack admin credentials
if [ -f ~/devstack/openrc ]; then
    echo "Loading OpenStack admin credentials from devstack..."
    source ~/devstack/openrc admin admin
elif [ -f /root/keystonerc_admin ]; then
    echo "Loading OpenStack admin credentials..."
    source /root/keystonerc_admin
elif [ -f ~/admin-openrc.sh ]; then
    echo "Loading OpenStack admin credentials..."
    source ~/admin-openrc.sh
else
    echo -e "${YELLOW}⚠ Could not find OpenStack credential file.${NC}"
    echo "Please source your admin credentials manually, then run:"
    echo "  openstack role add --user demo --project demo admin"
    echo ""
    exit 1
fi

echo ""
echo "Granting admin role to demo user..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check if demo user exists
if openstack user show demo &>/dev/null; then
    echo -e "${GREEN}✓${NC} Demo user exists"
else
    echo -e "${RED}✗${NC} Demo user does not exist. Creating..."
    openstack user create --domain default --password secret demo
fi

# Check if demo project exists
if openstack project show demo &>/dev/null; then
    echo -e "${GREEN}✓${NC} Demo project exists"
else
    echo -e "${RED}✗${NC} Demo project does not exist. Creating..."
    openstack project create --domain default --description "Demo Project" demo
fi

# Grant admin role to demo user on demo project
echo ""
echo "Granting admin role..."
if openstack role add --user demo --project demo admin 2>/dev/null; then
    echo -e "${GREEN}✓${NC} Admin role granted to demo user on demo project"
else
    echo -e "${YELLOW}⚠${NC} Admin role may already be assigned (this is OK)"
fi

# Also grant member role (for backward compatibility)
if openstack role add --user demo --project demo member 2>/dev/null; then
    echo -e "${GREEN}✓${NC} Member role granted to demo user"
else
    echo -e "${YELLOW}⚠${NC} Member role may already be assigned (this is OK)"
fi

# Verify roles
echo ""
echo "Current roles for demo user:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
openstack role assignment list --user demo --project demo --names

echo ""
echo "Testing demo user permissions..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Test with demo credentials
export OS_USERNAME=demo
export OS_PASSWORD=secret
export OS_PROJECT_NAME=demo
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
export OS_AUTH_URL=http://10.0.3.15/identity
export OS_IDENTITY_API_VERSION=3

# Test volume quota
if openstack quota show demo &>/dev/null; then
    echo -e "${GREEN}✓${NC} Demo user can view quotas"
    echo ""
    echo "Volume quotas:"
    openstack quota show demo | grep -E "(volumes|gigabytes)"
else
    echo -e "${RED}✗${NC} Demo user cannot view quotas"
fi

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                    SETUP COMPLETE                          ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo -e "${GREEN}✓${NC} Demo user now has admin permissions"
echo ""
echo "You can now use the demo user for all Ansible playbooks:"
echo "  Username: demo"
echo "  Password: secret"
echo "  Project: demo"
echo ""
echo "To test, run:"
echo "  export OS_CLOUD=mycloud"
echo "  openstack volume list"
echo "  openstack server list"
echo ""
