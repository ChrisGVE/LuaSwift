#!/bin/bash
set -euo pipefail

# Test all optional dependency combinations for LuaSwift
# This script uses the centralized configuration from test-matrix.json
#
# Usage:
#   ./scripts/test-combinations.sh           # Sequential execution
#   ./scripts/test-combinations.sh --parallel # Parallel execution

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source configuration
source "$SCRIPT_DIR/test-config.sh"

PARALLEL=false
if [ "${1:-}" = "--parallel" ]; then
    PARALLEL=true
fi

cd "$PROJECT_ROOT"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Track results
FAILED_COMBINATIONS=()

# Test a single combination
test_combination() {
    local bits="$1"
    local combo_name=$(generate_combo_name "$bits")

    echo -e "${YELLOW}Testing combination: $combo_name${NC}"

    # Set environment variables
    set_dep_env_vars "$bits"
    print_dep_config

    # Clean build directory
    swift package clean > /dev/null 2>&1 || true

    if swift build > /dev/null 2>&1; then
        echo -e "  Build: ${GREEN}PASS${NC}"
    else
        echo -e "  Build: ${RED}FAIL${NC}"
        FAILED_COMBINATIONS+=("$combo_name (build)")
        return 1
    fi

    # Run tests
    local test_log="/tmp/luaswift_test_${bits// /_}_$$.log"
    swift test > "$test_log" 2>&1 || true

    if grep -qE "(Test run with .* passed|Test Suite.*passed)" "$test_log"; then
        echo -e "  Tests: ${GREEN}PASS${NC}"
        rm -f "$test_log"
        echo ""
        return 0
    else
        echo -e "  Tests: ${RED}FAIL${NC}"
        tail -20 "$test_log"
        rm -f "$test_log"
        FAILED_COMBINATIONS+=("$combo_name (tests)")
        echo ""
        return 1
    fi
}

# Test a combination in background (for parallel mode)
test_combination_background() {
    local bits="$1"
    local combo_name=$(generate_combo_name "$bits")
    local log_file="/tmp/luaswift_test_${bits// /_}.log"

    if test_combination "$bits" > "$log_file" 2>&1; then
        echo -e "${GREEN}✓${NC} $combo_name" >> /tmp/luaswift_parallel_results.txt
    else
        echo -e "${RED}✗${NC} $combo_name" >> /tmp/luaswift_parallel_results.txt
        cat "$log_file" >> /tmp/luaswift_parallel_errors.txt
    fi
    rm -f "$log_file"
}

echo "========================================="
echo "LuaSwift Dependency Combinations Test"
echo "========================================="
echo ""
echo "Configuration loaded from: scripts/test-matrix.json"
echo "Optional dependencies: $(get_dep_count)"
echo "Total combinations: $((1 << $(get_dep_count)))"
echo ""

# Clear parallel result files if in parallel mode
if [ "$PARALLEL" = true ]; then
    rm -f /tmp/luaswift_parallel_results.txt /tmp/luaswift_parallel_errors.txt
    echo "Running tests in parallel..."
    echo ""
fi

# Generate all combinations
IFS=' ' read -ra COMBINATIONS <<< "$(generate_dep_combinations)"

if [ "$PARALLEL" = true ]; then
    for combo in "${COMBINATIONS[@]}"; do
        test_combination_background "$combo" &
    done

    wait

    echo ""
    echo "========================================="
    echo "Parallel Test Results"
    echo "========================================="
    if [ -f /tmp/luaswift_parallel_results.txt ]; then
        cat /tmp/luaswift_parallel_results.txt
    fi

    if [ -f /tmp/luaswift_parallel_errors.txt ]; then
        echo ""
        echo "========================================="
        echo "Failures"
        echo "========================================="
        cat /tmp/luaswift_parallel_errors.txt
        rm -f /tmp/luaswift_parallel_results.txt /tmp/luaswift_parallel_errors.txt
        exit 1
    fi

    rm -f /tmp/luaswift_parallel_results.txt
else
    for combo in "${COMBINATIONS[@]}"; do
        test_combination "$combo" || true
    done

    echo "========================================="
    echo "Summary"
    echo "========================================="

    if [ ${#FAILED_COMBINATIONS[@]} -eq 0 ]; then
        echo -e "${GREEN}All $((1 << $(get_dep_count))) combinations passed!${NC}"
        exit 0
    else
        echo -e "${RED}Failed combinations:${NC}"
        for failed in "${FAILED_COMBINATIONS[@]}"; do
            echo -e "  ${RED}✗${NC} $failed"
        done
        exit 1
    fi
fi
