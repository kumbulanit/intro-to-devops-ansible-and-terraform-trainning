#!/bin/bash
#=============================================================================
# Test Script for Day 5 Roles and Galaxy Labs
#=============================================================================
# This script runs various tests to validate the roles and playbooks
#
# Usage:
#   ./test-roles.sh [test-name]
#
# Available tests:
#   syntax    - Check playbook syntax
#   lint      - Run ansible-lint
#   molecule  - Run Molecule tests
#   all       - Run all tests
#
#=============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Base directory
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROLES_DIR="$BASE_DIR/roles"
PLAYBOOKS_DIR="$BASE_DIR/playbooks"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Day 5 Roles Testing Script${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Function to print success
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Function to print error
print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Function to print info
print_info() {
    echo -e "${YELLOW}→ $1${NC}"
}

# Test 1: Check syntax of all playbooks
test_syntax() {
    print_info "Testing playbook syntax..."
    
    for playbook in "$PLAYBOOKS_DIR"/*.yml; do
        if [ -f "$playbook" ]; then
            print_info "Checking $(basename $playbook)..."
            if ansible-playbook --syntax-check "$playbook" > /dev/null 2>&1; then
                print_success "Syntax OK: $(basename $playbook)"
            else
                print_error "Syntax Error: $(basename $playbook)"
                return 1
            fi
        fi
    done
    
    print_success "All playbook syntax checks passed!"
}

# Test 2: Run ansible-lint
test_lint() {
    print_info "Running ansible-lint..."
    
    # Check if ansible-lint is installed
    if ! command -v ansible-lint &> /dev/null; then
        print_error "ansible-lint not installed. Install with: pip install ansible-lint"
        return 1
    fi
    
    # Lint roles
    for role_dir in "$ROLES_DIR"/*/; do
        if [ -d "$role_dir" ]; then
            role_name=$(basename "$role_dir")
            print_info "Linting role: $role_name..."
            
            if ansible-lint "$role_dir" > /dev/null 2>&1; then
                print_success "Lint OK: $role_name"
            else
                print_error "Lint issues found in: $role_name"
                # Still continue to test other roles
            fi
        fi
    done
    
    print_success "Lint checks completed!"
}

# Test 3: Run Molecule tests
test_molecule() {
    print_info "Running Molecule tests..."
    
    # Check if molecule is installed
    if ! command -v molecule &> /dev/null; then
        print_error "Molecule not installed. Install with: pip install molecule[docker]"
        return 1
    fi
    
    # Find roles with molecule directory
    MOLECULE_ROLES=$(find "$ROLES_DIR" -name "molecule" -type d)
    
    if [ -z "$MOLECULE_ROLES" ]; then
        print_error "No Molecule test scenarios found"
        return 1
    fi
    
    for molecule_dir in $MOLECULE_ROLES; do
        role_dir=$(dirname "$molecule_dir")
        role_name=$(basename "$role_dir")
        
        print_info "Testing role with Molecule: $role_name..."
        
        cd "$role_dir"
        
        if molecule test; then
            print_success "Molecule tests passed: $role_name"
        else
            print_error "Molecule tests failed: $role_name"
            cd "$BASE_DIR"
            return 1
        fi
        
        cd "$BASE_DIR"
    done
    
    print_success "All Molecule tests passed!"
}

# Test 4: Verify role structure
test_structure() {
    print_info "Verifying role structure..."
    
    REQUIRED_DIRS=("tasks" "defaults" "handlers" "templates" "meta")
    
    for role_category in "$ROLES_DIR"/*; do
        if [ -d "$role_category" ]; then
            for role_dir in "$role_category"/*; do
                if [ -d "$role_dir" ]; then
                    role_name=$(basename "$role_dir")
                    print_info "Checking structure: $role_name..."
                    
                    # Check for required directories
                    for req_dir in "${REQUIRED_DIRS[@]}"; do
                        if [ ! -d "$role_dir/$req_dir" ]; then
                            print_error "Missing directory $req_dir in $role_name"
                            return 1
                        fi
                    done
                    
                    # Check for main.yml files
                    if [ ! -f "$role_dir/tasks/main.yml" ]; then
                        print_error "Missing tasks/main.yml in $role_name"
                        return 1
                    fi
                    
                    print_success "Structure OK: $role_name"
                fi
            done
        fi
    done
    
    print_success "All role structures verified!"
}

# Test 5: Check for README files
test_documentation() {
    print_info "Checking documentation..."
    
    for role_category in "$ROLES_DIR"/*; do
        if [ -d "$role_category" ]; then
            for role_dir in "$role_category"/*; do
                if [ -d "$role_dir" ]; then
                    role_name=$(basename "$role_dir")
                    
                    if [ ! -f "$role_dir/README.md" ]; then
                        print_error "Missing README.md in $role_name"
                        return 1
                    else
                        print_success "README.md found: $role_name"
                    fi
                fi
            done
        fi
    done
    
    print_success "All documentation checks passed!"
}

# Main test runner
run_tests() {
    local test_type=$1
    
    case $test_type in
        syntax)
            test_syntax
            ;;
        lint)
            test_lint
            ;;
        molecule)
            test_molecule
            ;;
        structure)
            test_structure
            ;;
        docs)
            test_documentation
            ;;
        all)
            test_structure && \
            test_documentation && \
            test_syntax && \
            test_lint && \
            test_molecule
            ;;
        *)
            echo "Usage: $0 {syntax|lint|molecule|structure|docs|all}"
            echo ""
            echo "Available tests:"
            echo "  syntax     - Check playbook syntax"
            echo "  lint       - Run ansible-lint"
            echo "  molecule   - Run Molecule tests"
            echo "  structure  - Verify role directory structure"
            echo "  docs       - Check for README files"
            echo "  all        - Run all tests"
            exit 1
            ;;
    esac
}

# Run tests
if [ $# -eq 0 ]; then
    print_info "No test specified, running all tests..."
    run_tests "all"
else
    run_tests "$1"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Testing Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
