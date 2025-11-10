#!/bin/bash
# Fix Non-Bootable Volumes in OpenStack
# Run this if you get "Block Device is not bootable" errors

echo "╔════════════════════════════════════════════════════════════╗"
echo "║     Fix Non-Bootable Volumes in OpenStack                 ║"
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

echo "Setting bootable flag on all volumes..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Get all volumes
volumes=$(openstack volume list -f value -c ID -c Name 2>/dev/null)

if [ -z "$volumes" ]; then
    echo -e "${YELLOW}⚠ No volumes found or unable to connect to OpenStack${NC}"
    echo "  Make sure your clouds.yaml is configured correctly"
    exit 1
fi

fixed=0
already_bootable=0
failed=0

while IFS=$'\t' read -r vol_id vol_name; do
    if [ -z "$vol_id" ]; then
        continue
    fi
    
    echo -n "Processing volume: $vol_name (ID: $vol_id)... "
    
    # Check if already bootable
    bootable=$(openstack volume show "$vol_id" -f value -c bootable 2>/dev/null)
    
    if [ "$bootable" == "true" ]; then
        echo -e "${GREEN}already bootable${NC}"
        ((already_bootable++))
    else
        # Set as bootable
        if openstack volume set --bootable "$vol_id" 2>/dev/null; then
            echo -e "${GREEN}✓ set to bootable${NC}"
            ((fixed++))
        else
            echo -e "${RED}✗ failed${NC}"
            ((failed++))
        fi
    fi
done <<< "$volumes"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}Already bootable: $already_bootable${NC}"
echo -e "${GREEN}Fixed: $fixed${NC}"
echo -e "${RED}Failed: $failed${NC}"
echo ""

if [ $failed -eq 0 ]; then
    echo -e "${GREEN}✓ All volumes are now bootable!${NC}"
    echo ""
    echo "You can now run your playbooks without bootable errors:"
    echo "  ansible-playbook scenario1_basic_vm.yml"
    echo ""
    exit 0
else
    echo -e "${YELLOW}⚠ Some volumes could not be set as bootable.${NC}"
    echo "  This may be due to permissions or volume state."
    echo ""
    exit 1
fi
