#!/bin/bash
# Grant Admin Access to All OpenStack Users
# For demo/training purposes only

echo "╔════════════════════════════════════════════════════════════╗"
echo "║     Grant Admin Access to OpenStack Users (Demo Only)     ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if OpenStack CLI is available
if ! command -v openstack &> /dev/null; then
    echo -e "${RED}✗ OpenStack CLI not found. Please install python-openstackclient${NC}"
    echo "  pip install python-openstackclient"
    exit 1
fi

echo -e "${YELLOW}⚠ WARNING: This will grant admin privileges to all users for demo purposes${NC}"
echo ""
read -p "Continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Aborted."
    exit 0
fi

echo ""
echo "Setting up OpenStack credentials..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Export admin credentials to interact with OpenStack
export OS_AUTH_URL=http://10.0.3.15/identity
export OS_PROJECT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=secret
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
export OS_IDENTITY_API_VERSION=3

echo ""
echo "Discovering all users in OpenStack..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Get all users
users=$(openstack user list -f value -c Name 2>/dev/null)

if [ -z "$users" ]; then
    echo -e "${RED}✗ Could not retrieve user list. Check your admin credentials.${NC}"
    echo "  Ensure admin password is correct in the script."
    exit 1
fi

echo "Found users:"
echo "$users"
echo ""

# Get all projects
echo "Discovering all projects..."
projects=$(openstack project list -f value -c Name 2>/dev/null)

echo "Found projects:"
echo "$projects"
echo ""

echo "Granting admin role to users..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

granted=0
skipped=0

# Loop through each user and project combination
while IFS= read -r user; do
    # Skip admin user (already has admin)
    if [ "$user" == "admin" ]; then
        continue
    fi
    
    while IFS= read -r project; do
        echo -n "Granting admin to user '$user' on project '$project'... "
        
        # Check if user already has admin role
        existing_role=$(openstack role assignment list --user "$user" --project "$project" --names -f value -c Role 2>/dev/null | grep -w "admin")
        
        if [ -n "$existing_role" ]; then
            echo -e "${YELLOW}SKIP (already has admin)${NC}"
            ((skipped++))
        else
            # Grant admin role
            if openstack role add --user "$user" --project "$project" admin 2>/dev/null; then
                echo -e "${GREEN}✓ SUCCESS${NC}"
                ((granted++))
            else
                echo -e "${RED}✗ FAILED${NC}"
            fi
        fi
    done <<< "$projects"
done <<< "$users"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}Granted admin access: $granted${NC}"
echo -e "${YELLOW}Already had admin: $skipped${NC}"
echo ""

# Specific focus on demo user in demo project
echo "Verifying demo user permissions..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if openstack user show demo &>/dev/null; then
    echo -e "${GREEN}✓${NC} demo user exists"
    
    # Ensure demo user has admin on demo project
    openstack role add --user demo --project demo admin 2>/dev/null
    
    # Check roles
    echo ""
    echo "demo user roles in demo project:"
    openstack role assignment list --user demo --project demo --names -f value -c Role
    
    echo ""
    echo -e "${GREEN}✓ demo user is ready for volume creation and all operations${NC}"
else
    echo -e "${YELLOW}⚠ demo user not found${NC}"
fi

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                       COMPLETE                             ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "All users now have admin access for demo purposes."
echo "You can now run Ansible playbooks without permission errors."
echo ""
echo "Example:"
echo "  ansible-playbook scenario1_basic_vm.yml"
echo ""
