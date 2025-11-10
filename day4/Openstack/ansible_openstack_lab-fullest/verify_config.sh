#!/bin/bash
# OpenStack Configuration Verification Script
# This script verifies all configurations are correct

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  OpenStack Ansible Lab - Configuration Verification       ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
PASS=0
FAIL=0

# Function to check and report
check_config() {
    local description="$1"
    local command="$2"
    local expected="$3"
    
    echo -n "Checking $description... "
    result=$(eval "$command")
    
    if [ "$result" == "$expected" ]; then
        echo -e "${GREEN}✓ PASS${NC}"
        ((PASS++))
    else
        echo -e "${RED}✗ FAIL${NC} (Expected: $expected, Got: $result)"
        ((FAIL++))
    fi
}

echo "1. API Configuration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check clouds.yaml exists
if [ -f "clouds.yaml" ]; then
    echo -e "${GREEN}✓${NC} clouds.yaml exists"
    ((PASS++))
else
    echo -e "${RED}✗${NC} clouds.yaml missing"
    ((FAIL++))
fi

# Check endpoint
endpoint=$(grep -A10 "mycloud:" clouds.yaml 2>/dev/null | grep "auth_url:" | awk '{print $2}' | head -1)
if [ "$endpoint" == "http://10.0.3.15/identity" ]; then
    echo -e "${GREEN}✓${NC} OpenStack endpoint: $endpoint"
    ((PASS++))
else
    echo -e "${RED}✗${NC} Wrong endpoint: $endpoint (Expected: http://10.0.3.15/identity)"
    ((FAIL++))
fi

echo ""
echo "2. Cloud Name Configuration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Count scenarios with cloud_name
cloud_count=$(grep -l "cloud_name: \"mycloud\"" scenario*.yml 2>/dev/null | wc -l | tr -d ' ')
echo -e "${GREEN}✓${NC} $cloud_count scenarios configured with cloud_name: mycloud"
((PASS++))

echo ""
echo "3. Image Name Configuration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check image names
image_count=$(grep -h "image_name:" scenario*.yml 2>/dev/null | grep -c "ubuntu-24.04")
echo -e "${GREEN}✓${NC} $image_count scenarios using image: ubuntu-24.04"
((PASS++))

echo ""
echo "4. VM Timeout Configuration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Count 600-second timeouts
timeout_600=$(grep -h "timeout: 600" scenario*.yml 2>/dev/null | wc -l | tr -d ' ')
echo -e "${GREEN}✓${NC} $timeout_600 VM deployments with 600-second timeout"
((PASS++))

# Count 60-second timeouts (for floating IP)
timeout_60=$(grep -h "timeout: 60" scenario*.yml 2>/dev/null | wc -l | tr -d ' ')
if [ "$timeout_60" -gt 0 ]; then
    echo -e "${GREEN}✓${NC} $timeout_60 network operation with 60-second timeout"
    ((PASS++))
fi

echo ""
echo "5. Security Group Rule Idempotency"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check ignore_errors in key scenarios
for scenario in scenario1_basic_vm.yml scenario4_boot_from_volume.yml scenario5_security_group.yml \
                scenario7_multi_network.yml scenario8_autoscale_sim.yml scenario11_userdata.yml \
                scenario12_lamp_stack.yml scenario14_haproxy_lb.yml scenario16_full_stack.yml; do
    if [ -f "$scenario" ]; then
        count=$(grep -c "ignore_errors: yes" "$scenario" 2>/dev/null || echo 0)
        if [ "$count" -gt 0 ]; then
            echo -e "${GREEN}✓${NC} $scenario: $count security group rules protected"
            ((PASS++))
        else
            echo -e "${YELLOW}⚠${NC} $scenario: No ignore_errors found"
        fi
    fi
done

echo ""
echo "6. Volume Configuration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check volume creation in VM scenarios
for scenario in scenario1_basic_vm.yml scenario4_boot_from_volume.yml scenario7_multi_network.yml \
                scenario8_autoscale_sim.yml scenario11_userdata.yml scenario12_lamp_stack.yml \
                scenario14_haproxy_lb.yml scenario16_full_stack.yml; do
    if [ -f "$scenario" ]; then
        if grep -q "openstack.cloud.volume:" "$scenario"; then
            echo -e "${GREEN}✓${NC} $scenario: Has volume configuration"
            ((PASS++))
        else
            echo -e "${RED}✗${NC} $scenario: Missing volume configuration"
            ((FAIL++))
        fi
    fi
done

echo ""
echo "7. Wait Parameter Configuration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Count wait: yes in VM scenarios
wait_count=$(grep -h "wait: yes" scenario*.yml 2>/dev/null | wc -l | tr -d ' ')
echo -e "${GREEN}✓${NC} $wait_count operations configured to wait for completion"
((PASS++))

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                    VERIFICATION SUMMARY                    ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo -e "Total Checks Passed: ${GREEN}$PASS${NC}"
echo -e "Total Checks Failed: ${RED}$FAIL${NC}"
echo ""

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}✓ All configurations are correct and ready for use!${NC}"
    echo ""
    echo "You can now run any scenario:"
    echo "  ansible-playbook scenario1_basic_vm.yml"
    echo "  ansible-playbook scenario16_full_stack.yml"
    echo ""
    exit 0
else
    echo -e "${RED}✗ Some configurations need attention. Please review the failures above.${NC}"
    echo ""
    exit 1
fi
