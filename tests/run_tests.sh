#!/bin/bash
# Test runner for reshade-linux.sh test suite
# Installs BATS if needed and runs all tests

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TESTS_DIR="$SCRIPT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if bats is installed
check_bats() {
    if ! command -v bats &> /dev/null; then
        echo -e "${YELLOW}BATS not found. Installing...${NC}"
        install_bats
    fi
}

# Install bats
install_bats() {
    echo "Installing bats framework..."
    
    # Try different installation methods
    if command -v apt-get &> /dev/null; then
        # Debian/Ubuntu
        sudo apt-get update && sudo apt-get install -y bats || {
            # Fallback: install from git
            install_bats_from_git
        }
    elif command -v dnf &> /dev/null; then
        # Fedora
        sudo dnf install -y bats || install_bats_from_git
    elif command -v brew &> /dev/null; then
        # macOS
        brew install bats-core || install_bats_from_git
    else
        install_bats_from_git
    fi
}

# Install BATS from git repo
install_bats_from_git() {
    echo "Installing BATS from GitHub..."
    local bats_tmp=$(mktemp -d)
    git clone https://github.com/bats-core/bats-core.git "$bats_tmp"
    cd "$bats_tmp"
    sudo ./install.sh /usr/local
    rm -rf "$bats_tmp"
}

# Source the main script functions for testing
setup_test_env() {
    # Make functions available to tests
    export RESHADE_SCRIPT="$PROJECT_ROOT/reshade-linux.sh"
}

# Run all tests
run_tests() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}Running ReShade Linux Test Suite${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    
    cd "$TESTS_DIR"
    
    local total_tests=0
    local passed_tests=0
    local failed_tests=0
    local failed_test_files=()
    
    # Run each test file
    for test_file in test_*.bats; do
        if [[ -f "$test_file" ]]; then
            echo -e "${BLUE}Running: $test_file${NC}"
            
            if bats "$test_file"; then
                ((passed_tests+=1))
            else
                ((failed_tests+=1))
                failed_test_files+=("$test_file")
            fi
            
            echo ""
        fi
    done
    
    # Print summary
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}Test Summary${NC}"
    echo -e "${BLUE}========================================${NC}"
    
    local total=$((passed_tests + failed_tests))
    
    if [[ $failed_tests -eq 0 ]]; then
        echo -e "${GREEN}✓ All tests passed! ($total tests)${NC}"
        return 0
    else
        echo -e "${RED}✗ Some tests failed${NC}"
        echo -e "  Total: $total tests"
        echo -e "  ${GREEN}Passed: $passed_tests${NC}"
        echo -e "  ${RED}Failed: $failed_tests${NC}"
        echo ""
        
        if [[ ${#failed_test_files[@]} -gt 0 ]]; then
            echo -e "${RED}Failed test files:${NC}"
            for file in "${failed_test_files[@]}"; do
                echo "  - $file"
            done
        fi
        
        return 1
    fi
}

# Generate coverage report
coverage_report() {
    echo ""
    echo -e "${BLUE}Test Coverage Summary${NC}"
    echo -e "${BLUE}========================================${NC}"
    
    echo "Core functions tested:"
    echo "  ✓ pickBestExeInDir() - Game exe detection"
    echo "  ✓ findSteamIconPath() - Icon discovery"
    echo "  ✓ getBuiltInGameDirPreset() - Preset lookups"
    echo "  ✓ Full detection pipeline - Integration tests"
    echo ""
    echo "Test fixtures:"
    echo "  • Mock Steam directory structures"
    echo "  • Mock game manifests (ACF files)"
    echo "  • Mock icon cache with priority"
    echo "  • Multi-exe game scenarios"
    echo "  • Utility filtering test cases"
}

# Main
main() {
    check_bats
    setup_test_env
    
    if run_tests; then
        coverage_report
        exit 0
    else
        echo ""
        echo -e "${RED}Test execution failed. See above for details.${NC}"
        exit 1
    fi
}

# Show help
show_help() {
    cat << EOF
ReShade Linux Test Suite Runner

Usage: $(basename "$0") [OPTIONS]

Options:
  -h, --help          Show this help message
  -i, --install-bats  Install BATS framework and exit
  --coverage          Show coverage report only
  -v, --verbose       Run tests with verbose output

Environment Variables:
  RESHADE_TEST_MODE=1    Enable test mode for the main script

Examples:
  # Run all tests
  $(basename "$0")
  
  # Install BATS only
  $(basename "$0") --install-bats
  
  # Run with verbose output
  $(basename "$0") --verbose

EOF
}

# Parse arguments
if [[ $# -gt 0 ]]; then
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        -i|--install-bats)
            check_bats
            echo "BATS is ready."
            exit 0
            ;;
        --coverage)
            coverage_report
            exit 0
            ;;
        -v|--verbose)
            export BATS_VERBOSE=1
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
fi

# Run tests
main "$@"
