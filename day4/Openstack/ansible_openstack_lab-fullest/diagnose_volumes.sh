#!/bin/bash
# Diagnose OpenStack Volume Issues
# Use this when volumes are stuck in "creating" status

echo "╔════════════════════════════════════════════════════════════╗"
echo "║     OpenStack Volume Diagnostics                          ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if OpenStack CLI is available
if ! command -v openstack &> /dev/null; then
    echo -e "${RED}✗ OpenStack CLI not found${NC}"
    exit 1
fi

echo "1. Checking Cinder (Volume) Service"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cinder_status=$(openstack volume service list -f value 2>/dev/null)
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Cinder service accessible${NC}"
    echo ""
    echo "Service Status:"
    openstack volume service list
else
    echo -e "${RED}✗ Cannot access Cinder service${NC}"
fi

echo ""
echo "2. Checking Volumes Stuck in Creating"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
stuck_volumes=$(openstack volume list --status creating -f value -c ID -c Name 2>/dev/null)

if [ -z "$stuck_volumes" ]; then
    echo -e "${GREEN}✓ No volumes stuck in 'creating' status${NC}"
else
    echo -e "${YELLOW}⚠ Found volumes stuck in 'creating':${NC}"
    echo "$stuck_volumes"
    echo ""
    echo "Would you like to delete these stuck volumes? (yes/no)"
    read -r response
    if [ "$response" == "yes" ]; then
        while IFS=$'\t' read -r vol_id vol_name; do
            echo -n "Deleting $vol_name... "
            if openstack volume delete "$vol_id" 2>/dev/null; then
                echo -e "${GREEN}✓${NC}"
            else
                # Force delete if normal delete fails
                echo -n "force deleting... "
                openstack volume delete --force "$vol_id" 2>/dev/null && echo -e "${GREEN}✓${NC}" || echo -e "${RED}✗${NC}"
            fi
        done <<< "$stuck_volumes"
    fi
fi

echo ""
echo "3. Checking Available Images"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
images=$(openstack image list --status active -f value -c Name 2>/dev/null)
if [ -z "$images" ]; then
    echo -e "${RED}✗ No active images found${NC}"
    echo "  Run: ansible-playbook scenario0_prerequisites.yml"
else
    echo -e "${GREEN}✓ Available images:${NC}"
    echo "$images"
fi

echo ""
echo "4. Checking Volume Quotas"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
quota=$(openstack quota show -f value -c volumes -c gigabytes 2>/dev/null)
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Quotas:${NC}"
    openstack quota show | grep -E "volumes|gigabytes"
else
    echo -e "${YELLOW}⚠ Could not retrieve quota information${NC}"
fi

echo ""
echo "5. Checking Cinder Logs (if accessible)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ -f "/var/log/cinder/cinder-volume.log" ]; then
    echo "Recent errors in Cinder logs:"
    tail -20 /var/log/cinder/cinder-volume.log | grep -i error
elif [ -f "/opt/stack/logs/c-vol.log" ]; then
    echo "Recent errors in Cinder logs (DevStack):"
    tail -20 /opt/stack/logs/c-vol.log | grep -i error
else
    echo -e "${YELLOW}⚠ Cinder log files not accessible${NC}"
    echo "  Run this script on the OpenStack controller node"
fi

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                  Common Issues & Fixes                     ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Issue 1: Volumes stuck in 'creating'"
echo "  Fix: Run this script and delete stuck volumes"
echo "       openstack volume delete --force <volume-id>"
echo ""
echo "Issue 2: No active images"
echo "  Fix: ansible-playbook scenario0_prerequisites.yml"
echo ""
echo "Issue 3: Cinder service down"
echo "  Fix (DevStack): sudo systemctl restart devstack@c-*"
echo "  Fix (Production): sudo systemctl restart openstack-cinder-*"
echo ""
echo "Issue 4: No space in backend"
echo "  Fix: Check LVM/Ceph storage backend"
echo "       df -h (for local disk)"
echo "       vgs (for LVM volume groups)"
echo ""
echo "Issue 5: Image not found when creating volume"
echo "  Fix: Verify image exists: openstack image list"
echo "       Use correct image name in playbook vars"
echo ""
